const path = require("path")

module.exports = {
    entry: "./main.js",
    output: {
        filename: "bst.js",
        path: path.resolve(__dirname, "dist"),
    },
};
