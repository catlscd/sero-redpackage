<template>
  <img :src="imgSrc" @error="error" />
</template>
<script>
export default {
  name: "MyImg",
  props: {
    src: String,
    defaultImg: String,
  },
  methods: {
    error() {
      if (!this.defaultImg || this.loaded) {
        return;
      }
      this.loaded = true;
      this.imgSrc = this.defaultImg;
    },
  },
  loaded: false,
  data() {
    return { imgSrc: this.src };
  },
};
</script>
