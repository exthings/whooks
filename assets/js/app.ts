import "../css/app.css";
import "vite/modulepreload-polyfill";
import { createInertiaApp, router } from "@inertiajs/svelte";
import { mount } from "svelte";
import axios from "axios";
import Layout from "$layouts/default.svelte";

axios.defaults.xsrfHeaderName = "x-csrf-token";

createInertiaApp({
  resolve: (name) => {
    const pages = import.meta.glob("./pages/**/*.svelte", { eager: true });
    let page = pages[`./pages/${name}.svelte`];
    return { default: page.default, layout: page.layout || Layout };
  },
  setup({ el, App, props }) {
    // @ts-ignore
    mount(App, { target: el, props });
  },
  progress: {
    delay: 250,
    color: "#000",
    includeCSS: true,
    showSpinner: false,
  },
  defaults: {
    visitOptions: () => {
      return { viewTransition: true }
    },
  },
} as any);

