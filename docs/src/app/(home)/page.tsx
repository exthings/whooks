import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowRight,
  BookOpen,
  Boxes,
  Braces,
  KeyRound,
  RefreshCcw,
  ShieldCheck,
  TerminalSquare,
  Webhook,
} from "lucide-react";

const primaryCards = [
  {
    title: "Quickstart",
    description: "Set up your first webhook flow and understand the basics.",
    href: "/docs/introduction/quickstart",
    label: "Start here",
    icon: BookOpen,
  },
  {
    title: "Topics",
    description:
      "Organize events by purpose and keep delivery flows predictable.",
    href: "/docs/features/topics",
    label: "Event routing",
    icon: Boxes,
  },
  {
    title: "Endpoints",
    description:
      "Register consumer URLs and configure how events are delivered.",
    href: "/docs/features/endpoints",
    label: "Delivery targets",
    icon: Webhook,
  },
];

const featureCards = [
  {
    title: "Retries",
    description: "Handle temporary failures with safer delivery attempts.",
    href: "/docs/features/retries",
    icon: RefreshCcw,
  },
  {
    title: "Idempotency",
    description:
      "Avoid duplicated side effects when events are delivered more than once.",
    href: "/docs/features/idempotency",
    icon: KeyRound,
  },
  {
    title: "Backoffice",
    description: "Monitor operational activity and support webhook management.",
    href: "/docs/features/backoffice",
    icon: TerminalSquare,
  },
  {
    title: "Security",
    description: "Verify requests and protect webhook communication.",
    href: "/docs/security/webhooks",
    icon: ShieldCheck,
  },
];

export const metadata: Metadata = {
  title: "Whooks - Open source webhooks delivery platform",
  description:
    "Whooks is 100% open source and self-hosted. Configure topics, endpoints, retries, idempotency, and monitoring with ease from day one.",
};

export default function HomePage() {
  return (
    <main className="min-h-screen bg-background">
      <section className="mx-auto w-full max-w-6xl px-6 pb-20 pt-16 md:pt-24">
        <div className="grid items-center gap-12 md:grid-cols-[0.95fr_1.05fr]">
          <div>
            <h1 className="max-w-2xl text-4xl font-bold tracking-tight text-zinc-950 md:text-5xl lg:text-[54px] lg:leading-[1.02] dark:text-zinc-50">
              Open source webhooks{" "}
              <span className="text-orange-500">delivery platform</span>
            </h1>

            <p className="mt-6 max-w-2xl text-lg leading-8 text-zinc-600 dark:text-zinc-400">
              Whooks is 100% open source and self-hosted. Configure topics,
              endpoints, retries, idempotency, and monitoring with{" "}
              <strong>ease from day one</strong>.
            </p>

            <div className="mt-9 flex flex-col gap-3 sm:flex-row">
              <Link
                href="/docs/introduction/quickstart"
                className="inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-zinc-950 px-6 text-sm font-semibold text-white shadow-sm transition hover:bg-zinc-800 dark:bg-white dark:text-zinc-950 dark:hover:bg-zinc-200"
              >
                Quickstart
                <ArrowRight className="h-4 w-4" />
              </Link>

              <Link
                href="/docs/features"
                className="inline-flex h-11 items-center justify-center gap-2 rounded-xl border border-zinc-200 bg-white px-6 text-sm font-semibold text-zinc-900 transition hover:border-orange-300 hover:bg-orange-50 hover:text-orange-700 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-100 dark:hover:border-orange-500/40 dark:hover:bg-orange-500/10 dark:hover:text-orange-300"
              >
                Explore features
                <ArrowRight className="h-4 w-4" />
              </Link>
            </div>

            <div className="mt-7 flex flex-col gap-3 text-sm text-zinc-500 dark:text-zinc-400 sm:flex-row sm:items-center">
              <span className="inline-flex items-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-orange-500" />
                Consumers
              </span>

              <span className="inline-flex items-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-orange-500" />
                Topics
              </span>

              <span className="inline-flex items-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-orange-500" />
                Endpoints
              </span>

              <span className="inline-flex items-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-orange-500" />
                Retries
              </span>

              <span className="inline-flex items-center gap-2">
                <span className="h-1.5 w-1.5 rounded-full bg-orange-500" />
                Monitoring
              </span>
            </div>
          </div>

          <div className="relative mx-auto w-full max-w-[560px] overflow-hidden rounded-[32px] bg-zinc-950 p-8 shadow-xl shadow-zinc-600/30  dark:border-zinc-800 dark:shadow-none">
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_10%,rgba(249,115,22,0.30),transparent_32%),radial-gradient(circle_at_80%_80%,rgba(255,255,255,0.10),transparent_34%)]" />

            <div className="relative z-10 flex items-start justify-between gap-2">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-orange-400">
                  Simple API
                </p>
                <p className="text-sm text-zinc-400">For publishing events</p>
              </div>
            </div>

            <div className="relative z-10 mt-6 rounded-3xl border border-white/10 bg-white/5 p-6 font-mono text-xs text-zinc-300 shadow-2xl shadow-black/20">
              <div className="mb-5 flex items-center gap-2">
                <span className="h-2.5 w-2.5 rounded-full bg-red-400" />
                <span className="h-2.5 w-2.5 rounded-full bg-yellow-400" />
                <span className="h-2.5 w-2.5 rounded-full bg-green-400" />
                <span className="ml-3 text-zinc-500">POST /v1/events</span>
              </div>

              <pre className="leading-4 [tab-size:2]">
                {`{
  "topic": "payment.created",
  "uid": "01KQX0KC863YV5T2D9GEQC93JP",
  "project_id": "project_01kqx0jsy7fe4s7hm0sf6jkkbb",
  "consumer_id": "consumer_01kqx08pmdfg3vqqfhppyawek1",
  "data": {
    "id": "fgyhbmzk2z4uhyuaj5eh3vmk5"
    "amount": 100,
    "currency": "BRL",
    "status": "created",
  }
}`}
              </pre>
            </div>

            <div className="relative z-10 my-4 h-px overflow-hidden bg-white/10">
              <div className="h-full w-1/3 animate-[delivery-line_2.8s_ease-in-out_infinite] bg-orange-400" />
            </div>

            <div className="relative z-10 grid grid-cols-3 gap-4">
              <div className="animate-[pulse_2.4s_ease-in-out_infinite] rounded-2xl border border-white/10 bg-white/[0.04] p-4">
                <p className="text-xs text-zinc-500">Topic</p>
                <p className="mt-2 text-xs font-semibold text-white">
                  payment.created
                </p>
              </div>

              <div className="animate-[pulse_2.4s_ease-in-out_infinite_0.4s] rounded-2xl border border-orange-400/30 bg-orange-400/10 p-4">
                <p className="text-xs text-orange-300/80">Retry</p>
                <p className="mt-2 text-xs font-semibold text-orange-200">
                  Exponential backoff
                </p>
              </div>

              <div className="animate-[pulse_2.4s_ease-in-out_infinite_0.8s] rounded-2xl border border-emerald-400/30 bg-emerald-400/10 p-4">
                <p className="text-xs text-emerald-300/80">Response</p>
                <p className="mt-2 text-xs font-semibold text-emerald-200">
                  200 OK
                </p>
              </div>
            </div>

            <style>{`
              @keyframes delivery-line {
                0% { transform: translateX(-120%); opacity: 0; }
                20% { opacity: 1; }
                70% { opacity: 1; }
                100% { transform: translateX(320%); opacity: 0; }
              }
            `}</style>
          </div>
        </div>
      </section>

      <section className="border-y border-zinc-200 bg-zinc-50/70 dark:border-zinc-800 dark:bg-zinc-950/40">
        <div className="mx-auto grid w-full max-w-6xl gap-4 px-6 py-12 md:grid-cols-3">
          {primaryCards.map((card) => {
            const Icon = card.icon;

            return (
              <Link
                key={card.title}
                href={card.href}
                className="group rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md dark:border-zinc-800 dark:bg-zinc-950"
              >
                <div className="mb-5 flex h-10 w-10 items-center justify-center rounded-xl border border-zinc-200 bg-zinc-50 text-zinc-700 transition group-hover:bg-zinc-950 group-hover:text-white dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-300 dark:group-hover:bg-white dark:group-hover:text-zinc-950">
                  <Icon className="h-5 w-5" />
                </div>

                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-zinc-500 dark:text-zinc-500">
                  {card.label}
                </p>

                <h2 className="mt-4 text-xl font-bold text-zinc-950 dark:text-zinc-50">
                  {card.title}
                </h2>

                <p className="mt-3 text-sm leading-6 text-zinc-600 dark:text-zinc-400">
                  {card.description}
                </p>

                <span className="mt-6 inline-flex items-center gap-1 text-sm font-semibold text-zinc-950 transition group-hover:translate-x-1 dark:text-zinc-50">
                  Open guide
                  <ArrowRight className="h-4 w-4" />
                </span>
              </Link>
            );
          })}
        </div>
      </section>

      <section className="mx-auto w-full max-w-6xl px-6 py-16">
        <div className="mb-8">
          <h2 className="text-2xl font-bold tracking-tight text-zinc-950 dark:text-zinc-50">
            Features
          </h2>

          <p className="mt-2 max-w-2xl text-sm leading-6 text-zinc-600 dark:text-zinc-400">
            Browse the core concepts and features used to operate webhook
            delivery with more control and visibility.
          </p>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          {featureCards.map((card) => {
            const Icon = card.icon;

            return (
              <Link
                key={card.title}
                href={card.href}
                className="group flex items-start justify-between gap-6 rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md dark:border-zinc-800 dark:bg-zinc-950"
              >
                <div className="flex gap-4">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-zinc-200 bg-zinc-50 text-zinc-700 transition group-hover:bg-zinc-950 group-hover:text-white dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-300 dark:group-hover:bg-white dark:group-hover:text-zinc-950">
                    <Icon className="h-5 w-5" />
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-zinc-950 dark:text-zinc-50">
                      {card.title}
                    </h3>

                    <p className="mt-2 text-sm leading-6 text-zinc-600 dark:text-zinc-400">
                      {card.description}
                    </p>
                  </div>
                </div>

                <ArrowRight className="mt-2 h-4 w-4 shrink-0 text-zinc-400 transition group-hover:translate-x-1 group-hover:text-zinc-950 dark:group-hover:text-zinc-50" />
              </Link>
            );
          })}
        </div>
      </section>
    </main>
  );
}
