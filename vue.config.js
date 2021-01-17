module.exports = {
  pluginOptions: {
    i18n: {
      locale: "zh",
      fallbackLocale: "zh",
      localeDir: "locales",
      enableInSFC: false,
    },
  },

  chainWebpack: (config) => {
    config.module
      .rule("images")
      .test(/\.(png|jpe?g|gif|webp)(\?.*)?$/)
      .use("url-loader")
      .loader(require.resolve("url-loader"))
      .options({
        limit: 4096,
        fallback: {
          loader: require.resolve("file-loader"),
          options: {
            name: (resourcePath, resourceQuery) => {
              if (resourcePath.indexOf("token-") != -1) {
                return "img/[name].[ext]";
              }
              return "img/[name].[hash:8].[ext]";
            },
          },
        },
      });

    return config;
  },

  publicPath: process.env.NODE_ENV == "development" ? "./" : "./v2",
  productionSourceMap: false,
  outputDir: "dist/v2",
  indexPath: "../index.html",
};
