import { paraglideVitePlugin } from "@inlang/paraglide-js";
import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import tailwindcss from "@tailwindcss/vite";
import { resolve } from "path";

// https://vitejs.dev/config/
export default defineConfig(({ command }) => {
  const isDev = command !== "build";

  if (isDev) {
    // Terminate the watcher when Phoenix quits
    process.stdin.on("close", () => {
      process.exit(0);
    });

    process.stdin.resume();
  }

  return {
    // publicDir: "static",
    plugins: [
      paraglideVitePlugin({
        project: "./project.inlang",
        outdir: "./js/paraglide",
        strategy: ["preferredLanguage", "baseLocale"],
      }),
      svelte({
        compilerOptions: {
          css: "external",
        },
      }),
      tailwindcss(),
    ],
    // base: "./",
    build: {
      target: "es2020",
      outDir: "../priv/static/assets",
      emptyOutDir: true,
      sourcemap: isDev,
      manifest: false,
      rollupOptions: {
        input: {
          app: "./js/app.ts",
        },
        output: {
          entryFileNames: "[name].js", // remove hash
          chunkFileNames: "[name]-[hash].js",
          assetFileNames: "[name][extname]",
        },
        // external: [/^node:.*/, /\.css$/, /fonts\/.*/, /images\/.*/],
        external: [/fonts\/.*/, /images\/.*/],
      },
    },
    resolve: {
      extensions: [".svelte", ".ts", ".js", ".json"],
      alias: {
        $lib: resolve(__dirname, "js/lib"),
        $pages: resolve(__dirname, "js/pages"),
        $layouts: resolve(__dirname, "js/layouts"),
        $components: resolve(__dirname, "js/components"),
        $utils: resolve(__dirname, "js/utils"),
        $types: resolve(__dirname, "js/types"),
        $paraglide: resolve(__dirname, "js/paraglide"),
      },
    },
  };
});
