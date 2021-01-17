import Vue from "vue";

import {
  ButtonPlugin,
  LayoutPlugin,
  DropdownPlugin,
  LinkPlugin,
  ModalPlugin,
  AlertPlugin,
  FormPlugin,
  FormGroupPlugin,
  InputGroupPlugin,
  FormInputPlugin,
  FormTextareaPlugin,
  OverlayPlugin,
  CardPlugin,
  ToastPlugin,
  TooltipPlugin,
  IconsPlugin,
  BadgePlugin,
} from "bootstrap-vue";

Vue.use(ButtonPlugin);
Vue.use(LayoutPlugin);
Vue.use(DropdownPlugin);
Vue.use(LinkPlugin);
Vue.use(ModalPlugin);
Vue.use(IconsPlugin);
Vue.use(AlertPlugin);
Vue.use(InputGroupPlugin);
Vue.use(FormInputPlugin);
Vue.use(OverlayPlugin);
Vue.use(FormPlugin);
Vue.use(FormGroupPlugin);
Vue.use(CardPlugin);
Vue.use(ToastPlugin);
Vue.use(FormTextareaPlugin);
Vue.use(TooltipPlugin);
Vue.use(BadgePlugin);
import "bootstrap/dist/css/bootstrap.css";
import "bootstrap-vue/dist/bootstrap-vue.css";

export default Vue;
