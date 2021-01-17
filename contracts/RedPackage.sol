pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./SeroInterface.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./HashID.sol";

contract RedPackage is SeroInterface, Ownable, HashID {
    using SafeMath for uint256;

    string private constant SERO_CURRENCY = "SERO";

    uint256 private constant baseNumber = 10000000;

    struct Friend {
        address user;
        string note;
    }
    struct UserFriend {
        mapping(address => bool) map;
        Friend[] friends;
    }

    struct TokenConfig {
        uint8 decimals; //小数点位数
        uint64 weight; //排序
        uint256 fees; //提现手续费
        uint256 minWithdrawAmount; //最小提现金额
        uint256 minSendAmount; //最小发送金额
        string currency; //SERO
    }

    struct UserPackageInfo {
        uint256 created;
        uint256 money;
        uint256 packageId;
        address user;
        bytes32 txhash;
    }

    struct UserOpenPackageRet {
        uint8 decimals;
        uint256 created;
        uint256 money;
        uint256 getMoney;
        string currency;
        string nickname;
        string shareCode;
        bytes32 txhash;
    }

    struct Package {
        uint8 typ; //0：拼手气，1：普通
        uint8 whoCanOpen;
        uint64 nums;
        uint64 openNums;
        uint256 money;
        uint256 remainAmount;
        uint256 openMoney;
        uint256 packageId;
        uint256 created;
        string currency;
        string note;
        string cover;
        string shareCode;
        address owner;
        uint256[] openedList; //打开的红包信息列表
        mapping(address => uint256) opened; //该地址是否已打开该红包
    }

    struct PackageRet {
        uint8 typ;
        uint8 decimal;
        uint64 nums;
        uint64 openNums;
        uint256 money;
        uint256 remainAmount;
        uint256 created;
        string currency;
        string shareCode;
    }

    UserPackageInfo[] private openPackageInfo; //每次打开的红包信息

    Package[] private packages; //所有的红包
    mapping(string => uint256) private shareCodeMap;
    mapping(address => uint256[]) private mySendPackages; //我发的红包
    mapping(address => UserPackageInfo[]) private myOpenPackages; //我抢的红包

    mapping(address => UserFriend) private friends;
    mapping(address => string) private nameMap;

    mapping(string => TokenConfig) private tokenMap;
    string[] public tokens;

    struct BalanceInfo {
        uint256 balance; //余额
        uint256 send; //发出的
        uint256 sendNums; //发出的数量
        uint256 get; //抢到的
        uint256 getNums; //抢到的数量
        uint256 getMax; //抢到的最大
    }

    struct UserCurrency {
        mapping(string => bool) exists;
        string[] currency;
    }

    //用户的红包余额
    mapping(address => mapping(string => BalanceInfo)) private balances;
    mapping(address => UserCurrency) private userCurrencyList;

    //提取 Token，还要扣除一定 SERO 作为手续费,0.1
    uint256 public seroFee = 1e17;

    constructor() public {
        addToken(18, 999, 1e17, 1e17, 1e16, "SERO");

        openPackageInfo.push(
            UserPackageInfo({
                created: now,
                money: 0,
                packageId: 0,
                user: address(0),
                txhash: 0x0
            })
        );

        packages.push(
            Package({
                typ: 0,
                nums: 0,
                money: 0,
                remainAmount: 0,
                packageId: 0,
                currency: "",
                note: "",
                cover: "",
                whoCanOpen: 0,
                owner: msg.sender,
                shareCode: "",
                created: now,
                openNums: 0,
                openMoney: 0,
                openedList: new uint256[](0)
            })
        );
    }

    bool public inited = false;

    function init(string memory _randStr) public onlyOwner {
        if (inited) {
            return;
        }
        randStr = _randStr;
        generateSalt();
        inited = true;
    }

    // function() public payable {}

    function balanceOf(string memory currency) public returns (uint256 amount) {
        return sero_balanceOf(currency);
    }

    function addUserCurrency(address user, string memory currency) private {
        UserCurrency storage userCurrency = userCurrencyList[user];
        if (!userCurrency.exists[currency]) {
            userCurrency.currency.push(currency);
            userCurrency.exists[currency] = true;
        }
    }

    function withdraw(string memory currency, uint256 amount) public payable {
        // require(
        //     bytes(tokenMap[currency].currency).length != 0,
        //     "Unsupported token"
        // );

        // 检查发送的手续费是不是 SERO
        bool msgIsSERO =
            Strings.equals(
                Strings.toSlice(sero_msg_currency()),
                Strings.toSlice(SERO_CURRENCY)
            );

        require(msgIsSERO, "Sero msg currency error");

        // TokenConfig memory tc = tokenMap[currency];

        require(amount >= 1, "Amount error");

        // 如果提的不是 SERO，还需要扣除一定 SERO 手续费
        bool isSERO =
            Strings.equals(
                Strings.toSlice(currency),
                Strings.toSlice(SERO_CURRENCY)
            );
        if (!isSERO) {
            //检查 SERO 手续费是否足够
            require(msg.value >= seroFee, "SERO fees error");
        }

        BalanceInfo storage adminInfo = balances[owner][currency];
        BalanceInfo storage balanceInfo = balances[msg.sender][currency];

        require(balanceInfo.balance >= amount, "Currency amount error");

        uint256 withdrawAmount = amount;
        uint256 fees = tokenMap[currency].fees;
        if (msg.sender == owner) {
            fees = 0;
        }

        if (fees > 0) {
            amount = amount.sub(fees);
            adminInfo.balance = adminInfo.balance.add(fees);
        }

        require(amount > 0, "Currency amount error");

        balanceInfo.balance = balanceInfo.balance.sub(withdrawAmount);

        addUserCurrency(owner, currency);

        if (!isSERO) {
            //Admin 增加 sero 手续费
            BalanceInfo storage adminSero = balances[owner][SERO_CURRENCY];
            adminSero.balance = adminSero.balance.add(msg.value);
            //用户扣除 sero 手续费
            // BalanceInfo storage userSero = balances[msg.sender]["SERO"];
            // userSero.balance = userSero.balance.sub(seroFee);
        }

        // 发送 Token
        require(
            sero_send_token(msg.sender, currency, amount),
            "Send token error"
        );
    }

    function setSeroFee(uint256 fee) public onlyOwner {
        seroFee = fee;
    }

    //用户资产列表
    function userBalances(uint256 start, uint256 perPage)
        public
        view
        returns (
            uint256 total,
            uint256 tokenSeroFee,
            string[] memory currencyList,
            BalanceInfo[] memory balancesList
        )
    {
        // TODO 待测试
        tokenSeroFee = seroFee;
        UserCurrency memory userCurrency = userCurrencyList[msg.sender];
        total = userCurrency.currency.length;
        uint256 end = start.add(perPage);
        if (end > total) {
            end = total;
        }
        if (perPage > total) {
            perPage = total;
        }

        balancesList = new BalanceInfo[](perPage);
        currencyList = new string[](perPage);

        uint256 i = 0;
        for (uint256 pos = start; pos < end; pos++) {
            currencyList[i] = userCurrency.currency[pos];
            balancesList[i] = balances[msg.sender][userCurrency.currency[pos]];
            i = i + 1;
        }
    }

    function userBalance(string memory _currency)
        public
        view
        returns (BalanceInfo memory balanceInfo)
    {
        balanceInfo = balances[msg.sender][_currency];
    }

    function myOpenPackageList(uint256 start, uint256 perPage)
        public
        view
        returns (uint256 total, UserOpenPackageRet[] memory openPackages)
    {
        total = myOpenPackages[msg.sender].length;

        if (start == 0) {
            start = total;
        }

        if (total < perPage) {
            perPage = total;
        }

        if (start < perPage) {
            perPage = start;
        }

        openPackages = new UserOpenPackageRet[](perPage);

        uint256 i = start - 1;
        uint256 pos = 0;
        while (pos < perPage) {
            UserPackageInfo memory up = myOpenPackages[msg.sender][i];
            Package memory p = packages[up.packageId];

            openPackages[pos] = UserOpenPackageRet({
                decimals: 0, // decimals: tokenMap[p.currency].decimals,
                money: p.money,
                currency: p.currency,
                shareCode: p.shareCode,
                getMoney: up.money,
                created: up.created,
                txhash: up.txhash,
                nickname: nameMap[p.owner]
            });

            if (i == 0) {
                break;
            }

            i -= 1;
            pos += 1;
        }
    }

    function mySendPackageList(uint256 start, uint256 perPage)
        public
        view
        returns (uint256 total, PackageRet[] memory sendPackages)
    {
        total = mySendPackages[msg.sender].length;

        if (start == 0) {
            start = total;
        }

        if (total < perPage) {
            perPage = total;
        }

        if (start < perPage) {
            perPage = start;
        }

        sendPackages = new PackageRet[](perPage);

        uint256 i = start - 1;
        uint256 pos = 0;
        while (pos < perPage) {
            Package memory p = packages[mySendPackages[msg.sender][i]];
            sendPackages[pos] = PackageRet({
                typ: p.typ,
                decimal: 0, //tokenMap[p.currency].decimals,
                nums: p.nums,
                openNums: p.openNums,
                money: p.money,
                remainAmount: p.remainAmount,
                created: p.created,
                currency: p.currency,
                shareCode: p.shareCode
            });

            if (i == 0) {
                break;
            }

            i -= 1;
            pos += 1;
        }
    }

    function packageOpenInfo(string memory code)
        public
        view
        returns (UserPackageInfo[] memory openedList, string[] memory nameList)
    {
        uint256 packageId = shareCodeMap[code];
        require(packageId > 0, "Package not found");
        Package memory p = packages[packageId];

        openedList = new UserPackageInfo[](p.openNums);
        nameList = new string[](p.openNums);

        for (uint256 i = 0; i < p.openNums; i++) {
            UserPackageInfo memory info = openPackageInfo[p.openedList[i]];
            nameList[i] = nameMap[info.user];

            info.packageId = 0;
            info.user = address(0);
            openedList[i] = info;
        }
    }

    function checkCanOpen(Package memory p) private view returns (bool) {
        bool isFriend = friends[p.owner].map[msg.sender];
        bool isOwner = p.owner == msg.sender;
        bool canOpen = isFriend || isOwner;

        return canOpen;
    }

    function packageInfo(string memory code)
        public
        view
        returns (
            PackageRet memory detail,
            bool canOpen,
            string memory note,
            string memory cover,
            string memory nickname
        )
    {
        uint256 packageId = shareCodeMap[code];
        require(packageId > 0, "Package not found");

        Package memory p = packages[packageId];
        canOpen = true;

        if (p.whoCanOpen == 1) {
            canOpen = checkCanOpen(p);
        }

        detail = PackageRet({
            typ: p.typ,
            decimal: 0, //tokenMap[p.currency].decimals,
            nums: p.nums,
            openNums: p.openNums,
            money: p.money,
            remainAmount: p.remainAmount,
            created: p.created,
            currency: p.currency,
            shareCode: p.shareCode
        });

        note = p.note;
        cover = p.cover;
        nickname = nameMap[p.owner];
    }

    function grabPackage(string memory code, string memory userStr) public {
        uint256 packageId = shareCodeMap[code];
        require(packageId > 0, "Package not found");
        Package storage p = packages[packageId];
        require(p.nums > 0, "Package error");
        require(p.opened[msg.sender] == 0, "Can't grabbed twice");
        require(p.openNums < p.nums, "OpenNums error");
        require(p.remainAmount > 0, "RemainAmount error");

        //  判断是否有抢的资格
        //只有好友才能抢
        if (p.whoCanOpen == 1) {
            bool canOpen = checkCanOpen(p);
            require(canOpen, "Only friends can open");
        }

        uint256 luck = 0;
        uint256 rand = 1;
        if (p.nums - p.openNums == 1) {
            luck = p.remainAmount;
        } else {
            if (p.typ == 1) {
                //普通红包，每个人都一样
                luck = p.money.div(p.nums);
            } else {
                uint256 min = 1;
                uint256 max = p.remainAmount.div(p.nums - p.openNums).mul(2);
                rand =
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                p.remainAmount,
                                userStr,
                                msg.sender,
                                now,
                                blockhash(block.number - 1),
                                block.difficulty
                            )
                        )
                    ) %
                    100;
                uint256 val = rand.mul(max).div(100);
                luck = val == 0 ? min : val;
            }
        }

        BalanceInfo storage balanceInfo = balances[msg.sender][p.currency];
        balanceInfo.balance = balanceInfo.balance.add(luck);
        balanceInfo.get = balanceInfo.get.add(luck);
        balanceInfo.getNums = balanceInfo.getNums.add(1);
        if (luck > balanceInfo.getMax) {
            balanceInfo.getMax = luck;
        }

        addUserCurrency(msg.sender, p.currency);

        uint256 packageInfoIndex = openPackageInfo.length;

        p.openNums += 1;
        p.openMoney = p.openMoney.add(luck);
        p.remainAmount = p.remainAmount.sub(luck);
        p.openedList.push(packageInfoIndex);
        p.opened[msg.sender] = packageInfoIndex;

        bytes32 txhash = sero_txHash();

        UserPackageInfo memory pkgInfo =
            UserPackageInfo({
                created: now,
                money: luck,
                packageId: packageId,
                user: msg.sender,
                txhash: txhash
            });

        openPackageInfo.push(pkgInfo);
        myOpenPackages[msg.sender].push(pkgInfo);
    }

    //发红包
    function createPackage(
        uint8 typ,
        uint64 nums,
        string memory currency,
        string memory note,
        string memory cover,
        uint8 whoCanOpen
    ) public payable {
        bool isMsgCurrency =
            Strings.equals(
                Strings.toSlice(sero_msg_currency()),
                Strings.toSlice(currency)
            );
        require(isMsgCurrency, "sero msg currency error");

        // require(
        //     bytes(tokenMap[currency].currency).length != 0,
        //     "Unsupported token"
        // );
        require(nums >= 1, "nums error");

        uint256 money = msg.value;

        // 检查最小发送金额
        // require(money >= tokenMap[currency].minSendAmount, "min money error");
        // 检查金额是否达到最小值
        require(money >= nums, "money error");

        uint256 packageId = packages.length;
        string memory shareCode = encode(packageId.add(baseNumber));

        require(shareCodeMap[shareCode] == 0, "ShareCode error!");

        Package memory p =
            Package({
                typ: typ,
                nums: nums,
                money: money,
                remainAmount: money,
                packageId: packageId,
                currency: currency,
                note: note,
                cover: cover,
                whoCanOpen: whoCanOpen,
                owner: msg.sender,
                shareCode: shareCode,
                created: now,
                openNums: 0,
                openMoney: 0,
                openedList: new uint256[](0)
            });
        packages.push(p);

        shareCodeMap[shareCode] = packageId;

        uint256[] storage myPackages = mySendPackages[msg.sender];
        myPackages.push(packageId);

        BalanceInfo storage balanceInfo = balances[msg.sender][currency];

        balanceInfo.sendNums = balanceInfo.sendNums.add(1);
        balanceInfo.send = balanceInfo.send.add(money);
    }

    function addToken(
        uint8 decimals,
        uint64 weight,
        uint256 fees,
        uint256 minWithdrawAmount,
        uint256 minSendAmount,
        string memory currency
    ) public onlyOwner {
        TokenConfig storage item = tokenMap[currency];

        if (bytes(item.currency).length == 0) {
            tokens.push(currency);
        }
        item.decimals = decimals;
        item.fees = fees;
        item.weight = weight;
        item.minWithdrawAmount = minWithdrawAmount;
        item.minSendAmount = minSendAmount;
        item.currency = currency;
    }

    // 返回 token 列表
    function tokenList() public view returns (TokenConfig[] memory result) {
        result = new TokenConfig[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            TokenConfig memory token = tokenMap[tokens[i]];
            result[i] = token;
        }
    }

    //设置昵称
    function setName(string memory name) public {
        nameMap[msg.sender] = name;
    }

    function getName() public view returns (string memory name) {
        name = nameMap[msg.sender];
    }

    function getFriends() public view returns (Friend[] memory friendList) {
        friendList = friends[msg.sender].friends;
    }

    // 添加好友
    function addFriend(address user, string memory note)
        public
        returns (bool success)
    {
        UserFriend storage userFriends = friends[msg.sender];
        if (userFriends.map[user]) {
            return true;
        }
        userFriends.map[user] = true;
        userFriends.friends.push(Friend({user: user, note: note}));
        return true;
    }

    function delFriend(address user, uint256 index) public {
        UserFriend storage userFriends = friends[msg.sender];
        if (!userFriends.map[user]) {
            return;
        }

        if (userFriends.friends[index].user != user) {
            return;
        }

        delete userFriends.map[user];
        uint256 lastIndex = userFriends.friends.length - 1;
        userFriends.friends[index] = userFriends.friends[lastIndex];
        delete userFriends.friends[lastIndex];
        userFriends.friends.length -= 1;
    }
}
