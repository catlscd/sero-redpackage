import Vue from "vue";
import VueRouter from "vue-router";
import Home from "../views/Home.vue";

Vue.use(VueRouter);

const routes = [
  {
    path: "/",
    name: "Home",
    component: Home,
  },
  {
    path: "/send-result",
    name: "SendResult",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/SendResult.vue"),
  },
  {
    path: "/send",
    name: "Send",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/Send.vue"),
  },
  {
    path: "/custom-cover",
    name: "CustomCover",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/CustomCover.vue"),
  },
  {
    path: "/detail",
    name: "Detail",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/Detail.vue"),
  },
  {
    path: "/my-package",
    name: "MyPackage",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/MyPackage.vue"),
  },
  {
    path: "/friends",
    name: "Friends",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/Friends.vue"),
  },
  {
    path: "/list",
    name: "List",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/List.vue"),
  },
  {
    path: "/nickname",
    name: "Nickname",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/Nickname.vue"),
  },
  {
    path: "/assets",
    name: "Assets",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/Assets.vue"),
  },
  {
    path: "/about",
    name: "About",
    component: () =>
      import(/* webpackChunkName: "red-envelope" */ "../views/About.vue"),
  },
];

const router = new VueRouter({
  routes,
});

export default router;
