let path = require("path");
let merge = require("webpack-merge");
const CopyWebpackPlugin = require('copy-webpack-plugin');

let prod = "production";
let dev = "development";

// determine build env
let TARGET_ENV = process.env.npm_lifecycle_event === "build" ? prod : dev;
let isDev = TARGET_ENV === dev;
let isProd = TARGET_ENV === prod;

let entryPath = path.join(__dirname, "./static/index.js");
let outputPath = path.resolve(__dirname + "/dist");
let outputFilename = "app.js";

console.log(`WEBPACK GO! Building for ${TARGET_ENV}`);

// common webpack config
let commonConfig = {
    module: {
        noParse: /\.elm$/,
        rules: [],
    },

    output: {
        path: outputPath,
        filename: outputFilename,
    },

    performance: {
        hints: false,
    },
};

// additional webpack settings for local env (when invoked by 'npm start')
if (isDev === true) {
    console.log("Serving locally...");
    module.exports = function() {
        return merge(commonConfig, {
            entry: entryPath,
            devServer: {
                contentBase: [".", "./static", "./assets"],
                headers: {
                    "Access-Control-Allow-Origin": "*",
                },
                stats: {
                    assets: false,
                    cached: false,
                    cachedAssets: false,
                    children: false,
                    chunks: false,
                    colors: true,
                    depth: true,
                    entrypoints: true,
                    errorDetails: true,
                    hash: false,
                    modules: true,
                    source: true,
                    timings: true,
                    version: false,
                    warnings: true,
                },
                proxy: {
                    "/api": {
                        target: "http://localhost:" + "42425",
                        proxyTimeout: 5 * 60 * 1000,
                    },
                },
            },

            plugins: [
                function() {
                    if (typeof this.options.devServer.hot === "undefined") {
                        this.plugin("done", function(stats) {
                            if (
                                stats.compilation.errors &&
                                stats.compilation.errors.length
                            ) {
                                console.log("Errors", {
                                    errors: stats.compilation.errors,
                                });
                                process.exit(1);
                            }
                        });
                    }
                },
            ],

            module: {
                rules: [
                    {
                        test: /\.elm$/,
                        exclude: [/elm-stuff/, /node_modules/],
                        use: [
                            {
                                loader: "elm-hot-webpack-loader",
                            },
                            {
                                loader: "elm-webpack-loader",
                                options: {
                                    verbose: true,
                                    // warn: true,
                                    debug: true,
                                },
                            },
                        ],
                    },
                ],
            },
        });
    };
}

// additional webpack settings for prod env (when invoked via 'npm run build')
if (isProd === true) {
    console.log("Building for prod...");

    module.exports = function() {
        return merge(commonConfig, {
            entry: entryPath,

            module: {
                rules: [
                    {
                        test: /\.elm$/,
                        exclude: [/elm-stuff/, /node_modules/],
                        use: [
                            {
                                loader: "elm-webpack-loader",
                                options: {
                                    optimize: true,
                                },
                            },
                        ],
                    },
                ],
            },

            plugins: [
                new CopyWebpackPlugin([
                    { from: 'static' }
                ]),
            ],
        });
    };
}
