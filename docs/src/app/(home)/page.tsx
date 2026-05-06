import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  ArrowRight,
  Boxes,
  CheckCircle2,
  Clock3,
  KeyRound,
  RefreshCcw,
  Rocket,
  ShieldCheck,
  Tags,
  Users,
  Webhook,
} from "lucide-react";

const coreFeatureCards = [
  {
    title: "Topics",
    href: "/docs/features/topics",
    icon: Boxes,
    description: (
      <>
        <span className="font-semibold text-zinc-950 transition-colors group-hover:text-orange-600 dark:text-zinc-50 dark:group-hover:text-orange-300">
          Organize event flows
        </span>{" "}
        by domain and keep delivery logic easier to understand, test, and
        maintain.
      </>
    ),
  },
  {
    title: "Endpoints",
    href: "/docs/features/endpoints",
    icon: Webhook,
    description: (
      <>
        <span className="font-semibold text-zinc-950 transition-colors group-hover:text-orange-600 dark:text-zinc-50 dark:group-hover:text-orange-300">
          Manage delivery targets
        </span>{" "}
        with more control, visibility, and operational clarity across webhook
        consumers.
      </>
    ),
  },
  {
    title: "Retries",
    href: "/docs/features/retries",
    icon: RefreshCcw,
    description: (
      <>
        Handle temporary failures with{" "}
        <span className="font-semibold text-zinc-950 transition-colors group-hover:text-orange-600 dark:text-zinc-50 dark:group-hover:text-orange-300">
          retry logic designed for safer delivery
        </span>{" "}
        and fewer missed events.
      </>
    ),
  },
  {
    title: "Idempotency",
    href: "/docs/features/idempotency",
    icon: KeyRound,
    description: (
      <>
        <span className="font-semibold text-zinc-950 transition-colors group-hover:text-orange-600 dark:text-zinc-50 dark:group-hover:text-orange-300">
          Prevent duplicate processing
        </span>{" "}
        and make repeated webhook deliveries safer to handle.
      </>
    ),
  },
  {
    title: "Event Tags",
    href: "/docs/features/event-tags",
    icon: Tags,
    description: (
      <>
        <span className="font-semibold text-zinc-950 transition-colors group-hover:text-orange-600 dark:text-zinc-50 dark:group-hover:text-orange-300">
          Classify and filter events
        </span>{" "}
        so teams can understand webhook activity with more context.
      </>
    ),
  },
  {
    title: "Security",
    href: "/docs/security/authentication",
    icon: ShieldCheck,
    description: (
      <>
        <span className="font-semibold text-zinc-950 transition-colors group-hover:text-orange-600 dark:text-zinc-50 dark:group-hover:text-orange-300">
          Protect webhook operations
        </span>{" "}
        with authentication guidance and safer communication practices.
      </>
    ),
  },
];

const platformCapabilities = [
  {
    title: "Consumer portal and dashboards",
    description:
      "Give consumers a dedicated experience to inspect and manage webhook flows.",
    href: "/docs/features/consumer-portal",
  },
  {
    title: "Backoffice for internal teams",
    description:
      "Operational visibility over operations and dashboards for delivery health, statuses, and issue identification.",
    href: "/docs/features/backoffice",
  },
  {
    title: "Fine-grained subscriptions",
    description:
      "Your consumers can subscribe to projects topics by setting up a endpoint.",
    href: "/docs/features/consumer-portal",
  },
  {
    title: "Retention",
    description:
      "Understand how webhook data can be retained and managed safely.",
    href: "/docs/security/retention",
  },
  {
    title: "Consuming webhooks",
    description:
      "Understand how to receive, verify, and process webhook events.",
    href: "/docs/introduction/consuming-webhooks",
  },
  {
    title: "Attempts & responses persistence",
    description:
      "Whooks keeps track of every attempt and responses. This can help you debug your integration or act as an audit log!",
    href: "/docs/features/persistence",
  },
  {
    title: "High availability",
    description:
      "Whooks is a distributed system designed to run in a high availability cluster.",
    href: "/docs/features/high-availability",
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
      {/* SECTION: HERO */}
      <section className="mx-auto container px-6 pb-20 pt-16 ">
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <h1 className="max-w-2xl text-4xl font-bold tracking-tight text-zinc-950 md:text-5xl lg:text-[54px] lg:leading-[1.02] dark:text-zinc-50">
              Open source webhooks{" "}
              <span className="text-orange-500">delivery platform</span>
            </h1>

            <p className="mt-6 max-w-2xl text-lg leading-8 text-zinc-600 dark:text-zinc-400">
              Whooks is 100% open source and self-hosted. Configure topics,
              endpoints, retries, idempotency, and monitoring with{" "}
              <strong className="font-semibold text-zinc-950 dark:text-zinc-50">
                ease from day one
              </strong>
              .
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

          {/* SECTION: HERO CODE CARD */}
          <div className="relative mx-auto w-full max-w-[560px] overflow-hidden rounded-[32px] bg-zinc-950 p-8 shadow-xl shadow-zinc-600/30 dark:border-zinc-800 dark:shadow-none">
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
    "id": "fgyhbmzk2z4uhyuaj5eh3vmk5",
    "amount": 100,
    "currency": "BRL",
    "status": "created"
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

      {/* SECTION: CORE FEATURES */}
      <section className="border-y border-zinc-200 bg-zinc-50/70 dark:border-zinc-800 dark:bg-zinc-950/40">
        <div className="mx-auto container px-6 py-20">
          <div className="mx-auto mb-12 max-w-3xl text-center">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-orange-500">
              Core features
            </p>

            <h2 className="mt-4 text-3xl font-bold tracking-tight text-zinc-950 md:text-5xl dark:text-zinc-50">
              Webhooks are harder than they seem.
            </h2>

            <p className="mt-5 text-base leading-7 text-zinc-600 dark:text-zinc-400">
              Whooks gives teams the building blocks to organize, deliver,
              secure, and monitor webhook operations with more confidence.
            </p>
          </div>

          <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-3">
            {coreFeatureCards.map((card) => {
              const Icon = card.icon;

              return (
                <Link
                  key={card.title}
                  href={card.href}
                  className="group min-h-[280px] rounded-3xl border border-zinc-200 bg-white p-7 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:border-orange-200 hover:shadow-xl hover:shadow-orange-100/60 dark:border-zinc-800 dark:bg-zinc-950 dark:hover:border-orange-500/40 dark:hover:shadow-none"
                >
                  <div className="mb-8 flex h-12 w-12 items-center justify-center rounded-2xl border border-zinc-200 bg-zinc-50 text-zinc-800 transition-colors duration-300 group-hover:border-orange-200 group-hover:bg-orange-50 group-hover:text-orange-500 dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-300 dark:group-hover:border-orange-500/40 dark:group-hover:bg-orange-500/10 dark:group-hover:text-orange-300">
                    <Icon className="h-5 w-5" />
                  </div>

                  <h3 className="text-xl font-bold text-zinc-950 dark:text-zinc-50">
                    {card.title}
                  </h3>

                  <p className="mt-4 text-sm leading-7 text-zinc-600 dark:text-zinc-400">
                    {card.description}
                  </p>

                  <span className="mt-7 inline-flex items-center gap-2 text-sm font-semibold text-zinc-950 transition-colors group-hover:text-orange-600 dark:text-zinc-50 dark:group-hover:text-orange-300">
                    Read guide
                    <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                  </span>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      {/* SECTION: PORTAL / DASHBOARD SHOWCASE */}
      <section className="border-b border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="mx-auto container px-6 py-20">
          {/* SHOWCASE CTA BAR */}
          <div className="mb-8 rounded-2xl bg-zinc-950 px-8 py-8 text-white shadow-xl shadow-zinc-300/20 dark:shadow-none md:px-10">
            <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
              <div className="flex-1">
                <h2 className="text-3xl font-bold tracking-tight">
                  Simple integration with SDK{" "}
                  <span className="font-normal text-zinc-500">
                    (coming soon)
                  </span>{" "}
                  or through REST API{" "}
                </h2>

                <p className="mt-4 font-mono text-base text-zinc-300 md:text-lg">
                  whooks.events.create({"{your event}"})
                </p>
              </div>

              <div className="flex flex-wrap gap-3">
                <Link
                  href="/docs/introduction/quickstart"
                  className="inline-flex h-11 min-w-[136px] items-center justify-center whitespace-nowrap rounded-xl bg-orange-500 px-5 text-sm font-semibold text-white transition hover:bg-orange-600"
                >
                  Get started
                </Link>

                <Link
                  href="/docs/introduction"
                  className="inline-flex h-11 min-w-[136px] items-center justify-center whitespace-nowrap rounded-xl border border-white/15 px-5 text-sm font-semibold text-white transition hover:border-orange-400 hover:bg-white/5"
                >
                  Read the docs
                </Link>
              </div>
            </div>
          </div>

          {/* SHOWCASE CONTENT */}
          <div className="grid items-stretch gap-5 lg:grid-cols-[0.68fr_1.32fr]">
            {/* LEFT SUPPORT CARDS */}
            <div className="grid gap-5">
              <div className="rounded-2xl border border-zinc-200 bg-zinc-50 p-6 transition hover:border-orange-200 hover:bg-orange-50/40 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-orange-500/30 dark:hover:bg-orange-500/5">
                <div className="mb-5 flex h-10 w-10 items-center justify-center rounded-xl bg-orange-100 text-orange-600 dark:bg-orange-500/10 dark:text-orange-300">
                  <Users className="h-5 w-5" />
                </div>

                <h3 className="text-xl font-semibold leading-tight tracking-tight text-zinc-950 dark:text-zinc-50">
                  Consumer visibility
                </h3>

                <p className="mt-3 text-sm leading-7 text-zinc-600 dark:text-zinc-400">
                  Give users a clear place to inspect endpoints and delivery
                  activity.
                </p>
              </div>

              <div className="rounded-2xl border border-zinc-200 bg-zinc-50 p-6 transition hover:border-orange-200 hover:bg-orange-50/40 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-orange-500/30 dark:hover:bg-orange-500/5">
                <div className="mb-5 flex h-10 w-10 items-center justify-center rounded-xl bg-orange-100 text-orange-600 dark:bg-orange-500/10 dark:text-orange-300">
                  <Clock3 className="h-5 w-5" />
                </div>

                <h3 className="text-xl font-semibold leading-tight tracking-tight text-zinc-950 dark:text-zinc-50">
                  Faster troubleshooting
                </h3>

                <p className="mt-3 text-sm leading-7 text-zinc-600 dark:text-zinc-400">
                  Track delivery health, review statuses, and identify issues
                  faster.
                </p>
              </div>

              <div className="rounded-2xl border border-zinc-200 bg-zinc-50 p-6 transition hover:border-orange-200 hover:bg-orange-50/40 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-orange-500/30 dark:hover:bg-orange-500/5">
                <div className="mb-5 flex h-10 w-10 items-center justify-center rounded-xl bg-orange-100 text-orange-600 dark:bg-orange-500/10 dark:text-orange-300">
                  <Rocket className="h-5 w-5" />
                </div>

                <h3 className="text-xl font-semibold leading-tight tracking-tight text-zinc-950 dark:text-zinc-50">
                  Backoffice ready
                </h3>

                <p className="mt-3 text-sm leading-7 text-zinc-600 dark:text-zinc-400">
                  Support internal teams as webhook volume and complexity grow.
                </p>
              </div>
            </div>

            {/* RIGHT MAIN PANEL */}
            <div className="rounded-[28px] border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-900 md:p-7">
              <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                <div className="max-w-2xl">
                  <h3 className="text-2xl font-semibold tracking-tight text-zinc-950 md:text-[34px] md:leading-[1.12] dark:text-zinc-50">
                    Webhook management portal
                  </h3>

                  <p className="mt-3 text-sm leading-7 text-zinc-600 dark:text-zinc-400 md:text-base">
                    Inspect endpoints, monitor delivery health, and support
                    webhook operations from a clearer interface.
                  </p>
                </div>

                <Link
                  href="/docs/features/backoffice"
                  className="inline-flex shrink-0 items-center gap-2 text-sm font-semibold text-zinc-950 transition hover:text-orange-600 dark:text-zinc-50 dark:hover:text-orange-300"
                >
                  Learn more
                  <ArrowRight className="h-4 w-4" />
                </Link>
              </div>

              <div className="mt-6 overflow-hidden rounded-2xl border border-orange-200 bg-white shadow-sm dark:border-orange-500/20 dark:bg-zinc-950">
                <Image
                  src="/img/whooks-dashboard-preview.png"
                  alt="Preview of the Whooks webhook dashboard interface"
                  width={1448}
                  height={1086}
                  className="h-auto w-full object-cover"
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* SECTION: ALL-IN-ONE PLATFORM */}
      <section className="bg-zinc-950 text-white">
        <div className="mx-auto grid container gap-12 px-6 py-20 lg:grid-cols-[0.85fr_1.15fr]">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-orange-400">
              Complete solution
            </p>

            <h2 className="mt-4 text-3xl font-bold tracking-tight md:text-5xl">
              All-in-one webhook platform
            </h2>

            <p className="mt-5 max-w-md text-base leading-7 text-zinc-400">
              Whooks combines organizations, events, endpoints, delivery
              control, retries, security, and operational visibility in one
              workflow.
            </p>

            <Link
              href="/docs/introduction"
              className="mt-8 inline-flex h-11 items-center justify-center gap-2 rounded-xl border border-white/15 bg-white/10 px-6 text-sm font-semibold text-white transition hover:border-orange-400/50 hover:bg-orange-500/15 hover:text-orange-200"
            >
              Explore all docs
              <ArrowRight className="h-4 w-4" />
            </Link>
          </div>

          <div className="grid gap-5 md:grid-cols-2">
            {platformCapabilities.map((item) => (
              <Link
                key={item.title}
                href={item.href}
                className="group flex gap-4 rounded-2xl border border-white/10 bg-white/[0.04] p-5 transition hover:-translate-y-0.5 hover:border-orange-400/40 hover:bg-white/[0.06]"
              >
                <div className="mt-1 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-emerald-500/10 text-emerald-400 transition group-hover:bg-orange-500/10 group-hover:text-orange-300">
                  <CheckCircle2 className="h-4 w-4" />
                </div>

                <div>
                  <h3 className="font-semibold text-white transition group-hover:text-orange-200">
                    {item.title}
                  </h3>

                  <p className="mt-2 text-sm leading-6 text-zinc-400">
                    {item.description}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}
