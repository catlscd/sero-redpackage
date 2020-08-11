<template>
  <b-container id="custom-word">
    <div class="qa-item">
      <strong class="title">什么是红包口令定制？</strong>
      <div class="text-muted content">
        <p>
          默认的口令是随机生成的不定位字母，如：HGSX2VN
          。口令定制可以在前面添加广告语（尽量简单），如定制后的口令可以是:
          SERO牛逼_SHDGJKBB
        </p>
      </div>
    </div>
    <div class="text-center" style="margin-top:60px;">
      <b-button variant="warning">我要定制</b-button>
    </div>
  </b-container>
</template>
<script>
export default {
  created() {
    this.$root.changeNavTitle("红包口令定制");
  },
};
</script>
<style></style>
