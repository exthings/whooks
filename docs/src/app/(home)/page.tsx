import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  ArrowRight,
  Boxes,
  Building2,
  CheckCircle2,
  Clock3,
  Gamepad2,
  KeyRound,
  Landmark,
  RefreshCcw,
  Rocket,
  ServerCog,
  ShieldCheck,
  ShoppingCart,
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
    title: "Consumer portal",
    description: "Give consumers a dedicated interface to manage webhook flows.",
    href: "/docs/features/consumer-portal",
  },
  {
    title: "Backoffice",
    description: "Monitor delivery health and support internal operations.",
    href: "/docs/features/backoffice",
  },
  {
    title: "Event tags",
    description: "Classify events with more context and operational clarity.",
    href: "/docs/features/event-tags",
  },
  {
    title: "Retention",
    description: "Understand how webhook data is retained and managed.",
    href: "/docs/security/retention",
  },
  {
    title: "Consuming webhooks",
    description: "Learn how to receive, verify, and process webhook events.",
    href: "/docs/introduction/consuming-webhooks",
  },
  {
    title: "Authentication",
    description: "Protect webhook communication with safer request validation.",
    href: "/docs/security/authentication",
  },
  {
    title: "Idempotency",
    description: "Prevent duplicate processing from repeated event deliveries.",
    href: "/docs/features/idempotency",
  },
  {
    title: "Retries",
    description: "Handle temporary failures with safer delivery attempts.",
    href: "/docs/features/retries",
  },
];

const industryUseCases = [
  {
    id: "fintech",
    label: "Fintech",
    icon: Landmark,
    title: "Financial events need reliable delivery",
    description:
      "Whooks helps fintech teams deliver payment, account, onboarding, compliance, and operational events with more control.",
    items: [
      {
        title: "Payment events",
        description:
          "Publish payment lifecycle updates such as created, approved, failed, refunded, and settled.",
      },
      {
        title: "Operational alerts",
        description:
          "Give teams better visibility into failed deliveries, retries, and endpoint health.",
      },
      {
        title: "Compliance workflows",
        description:
          "Support critical event flows with authentication, retention, and delivery traceability.",
      },
    ],
  },
  {
    id: "igaming",
    label: "iGaming",
    icon: Gamepad2,
    title: "Real-time events for gaming operations",
    description:
      "Use Whooks to support wallet, player, transaction, risk, and lifecycle events across gaming platforms.",
    items: [
      {
        title: "Wallet updates",
        description:
          "Deliver deposit, withdrawal, balance, and transaction events to internal and external systems.",
      },
      {
        title: "Player lifecycle",
        description:
          "Notify services when player accounts, verification states, or activity events change.",
      },
      {
        title: "Risk operations",
        description:
          "Route risk, fraud, and monitoring events with stronger delivery control.",
      },
    ],
  },
  {
    id: "saas",
    label: "SaaS",
    icon: Building2,
    title: "Customer-facing webhooks for SaaS products",
    description:
      "Let customers receive product updates, lifecycle events, and integration notifications from your platform.",
    items: [
      {
        title: "Product events",
        description:
          "Send account, user, subscription, billing, and workspace updates to customer endpoints.",
      },
      {
        title: "Integration workflows",
        description:
          "Help customers connect your product to their internal tools and automations.",
      },
      {
        title: "Developer experience",
        description:
          "Give developers clearer event documentation, retries, and endpoint management.",
      },
    ],
  },
  {
    id: "marketplaces",
    label: "Marketplaces",
    icon: ShoppingCart,
    title: "Coordinate events across buyers, sellers, and services",
    description:
      "Use Whooks to connect order, seller, payment, refund, logistics, and notification flows.",
    items: [
      {
        title: "Order lifecycle",
        description:
          "Publish order created, paid, shipped, canceled, refunded, and delivered events.",
      },
      {
        title: "Seller operations",
        description:
          "Notify seller systems about inventory, payouts, disputes, and fulfillment events.",
      },
      {
        title: "Service coordination",
        description:
          "Connect payments, logistics, notifications, and internal operations through event flows.",
      },
    ],
  },
  {
    id: "platforms",
    label: "Internal platforms",
    icon: ServerCog,
    title: "Infrastructure for event-driven operations",
    description:
      "Support engineering and operations teams with webhook infrastructure, monitoring, and delivery control.",
    items: [
      {
        title: "Internal integrations",
        description:
          "Connect services and teams through consistent event publishing and delivery patterns.",
      },
      {
        title: "Backoffice visibility",
        description:
          "Give support and operations teams a clearer view of webhook delivery health.",
      },
      {
        title: "Audit-friendly flows",
        description:
          "Keep delivery attempts, responses, retries, and event history easier to inspect.",
      },
    ],
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
      <section className="mx-auto w-full max-w-7xl px-6 pb-20 pt-16">
        <div className="flex flex-col items-center justify-between gap-12 lg:flex-row">
          <div className="flex-1">
            <h1 className="max-w-2xl text-4xl font-bold leading-tight tracking-tight text-zinc-950 md:text-5xl lg:text-6xl dark:text-zinc-50">
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
          <div className="relative mx-auto w-full max-w-xl overflow-hidden rounded-3xl bg-zinc-950 p-8 shadow-xl shadow-zinc-600/30 dark:border-zinc-800 dark:shadow-none">
            <div className="absolute inset-0 bg-gradient-to-br from-orange-500/20 via-zinc-950 to-zinc-900" />

            <div className="relative z-10 flex items-start justify-between gap-2">
              <div>
                <p className="text-xs font-semibold uppercase tracking-widest text-orange-400">
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

              <pre className="leading-4">
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
              <div className="animate-[pulse_2.4s_ease-in-out_infinite] rounded-2xl border border-white/10 bg-white/5 p-4">
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
        <div className="mx-auto w-full max-w-7xl px-6 py-20">
          <div className="mx-auto mb-12 max-w-3xl text-center">
            <p className="text-sm font-semibold uppercase tracking-widest text-orange-500">
              Core features
            </p>

            <h2 className="mt-4 text-3xl font-bold tracking-tight text-zinc-950 md:text-5xl dark:text-zinc-50">
              Webhooks made simple
            </h2>

            <p className="mt-5 text-base leading-7 text-zinc-600 dark:text-zinc-400">
              Whooks gives teams the building blocks to organize, deliver,
              secure, and monitor webhook operations with more confidence and
              ease.
            </p>
          </div>

          <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-3">
            {coreFeatureCards.map((card) => {
              const Icon = card.icon;

              return (
                <Link
                  key={card.title}
                  href={card.href}
                  className="group min-h-72 rounded-3xl border border-zinc-200 bg-white p-7 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:border-orange-200 hover:shadow-xl hover:shadow-orange-100/60 dark:border-zinc-800 dark:bg-zinc-950 dark:hover:border-orange-500/40 dark:hover:shadow-none"
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
        <div className="mx-auto w-full max-w-7xl px-6 py-20">
          {/* SHOWCASE CTA BAR */}
          <div className="mb-8 rounded-2xl bg-zinc-950 px-8 py-8 text-white shadow-xl shadow-zinc-300/20 dark:shadow-none md:px-10">
            <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between">
              <div className="flex-1">
                <h2 className="text-3xl font-bold tracking-tight">
                  Simple integration with SDK{" "}
                  <span className="font-normal text-zinc-500">
                    (coming soon)
                  </span>{" "}
                  <br />
                  or through REST API{" "}
                </h2>

                <p className="mt-4 font-mono text-base text-zinc-300 md:text-lg">
                  whooks.events.create
                  <span className="text-orange-500">{"({your event})"}</span>
                </p>
              </div>

              <div className="flex flex-wrap gap-3">
                <Link
                  href="/docs/introduction/quickstart"
                  className="inline-flex h-11 min-w-36 items-center justify-center whitespace-nowrap rounded-xl bg-orange-500 px-5 text-sm font-semibold text-white transition hover:bg-orange-600"
                >
                  Get started
                </Link>

                <Link
                  href="/docs/introduction"
                  className="inline-flex h-11 min-w-36 items-center justify-center whitespace-nowrap rounded-xl border border-white/15 px-5 text-sm font-semibold text-white transition hover:border-orange-400 hover:bg-white/5"
                >
                  Read the docs
                </Link>
              </div>
            </div>
          </div>

          {/* SHOWCASE CONTENT */}
          <div className="grid items-stretch gap-5">
            {/* APP PORTAL PANEL */}
            <div className="rounded-2xl border border-zinc-200 bg-zinc-50 p-6 dark:border-zinc-800 dark:bg-zinc-900 md:p-7">
              <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                <div className="max-w-2xl">
                  <h3 className="text-2xl font-semibold leading-tight tracking-tight text-zinc-950 md:text-4xl dark:text-zinc-50">
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

            {/* BOTTOM SUPPORT CARDS */}
            <div className="grid gap-5 md:grid-cols-3">
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
                  Full featured UI
                </h3>

                <p className="mt-3 text-sm leading-7 text-zinc-600 dark:text-zinc-400">
                  Support internal teams and consumers with dashboards and
                  delivery attempts.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* SECTION: ALL-IN-ONE PLATFORM */}
      <section className="bg-zinc-950 text-white">
        <div className="mx-auto grid w-full max-w-7xl gap-12 px-6 py-20 lg:grid-cols-2">
          <div>
            <p className="text-sm font-semibold uppercase tracking-widest text-orange-400">
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
                className="group flex items-start gap-4 rounded-2xl border border-white/10 bg-white/5 p-5 transition hover:-translate-y-0.5 hover:border-orange-400/40 hover:bg-white/10"
              >
                <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-emerald-500/10 text-emerald-400 transition group-hover:bg-orange-500/10 group-hover:text-orange-300">
                  <CheckCircle2 className="h-4 w-4" />
                </div>

                <div>
                  <h3 className="h-11 font-semibold text-white transition group-hover:text-orange-200">
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

      {/* SECTION: USE CASES BY INDUSTRY */}
      <section className="border-b border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-950">
        <div className="mx-auto w-full max-w-7xl px-6 py-20">
          <div className="mb-10 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="text-sm font-semibold uppercase tracking-widest text-orange-500">
                Use cases
              </p>

              <h2 className="mt-4 max-w-3xl text-3xl font-bold tracking-tight text-zinc-950 md:text-5xl dark:text-zinc-50">
                Built for teams that rely on event delivery
              </h2>
            </div>

            <p className="max-w-xl text-base leading-7 text-zinc-600 dark:text-zinc-400">
              Whooks supports product and engineering teams across financial
              services, platforms, SaaS, marketplaces, and event-driven
              operations.
            </p>
          </div>

          <div className="rounded-3xl border border-zinc-200 bg-zinc-50 p-4 dark:border-zinc-800 dark:bg-zinc-900">
            {industryUseCases.map((industry, index) => (
              <input
                key={industry.id}
                id={`industry-${industry.id}`}
                name="industry"
                type="radio"
                defaultChecked={index === 0}
                className="peer hidden"
              />
            ))}

            <div className="mb-6 flex flex-wrap gap-2 rounded-2xl border border-zinc-200 bg-white p-2 dark:border-zinc-800 dark:bg-zinc-950">
              {industryUseCases.map((industry) => {
                const Icon = industry.icon;

                return (
                  <label
                    key={industry.id}
                    htmlFor={`industry-${industry.id}`}
                    className="inline-flex cursor-pointer items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold text-zinc-600 transition hover:bg-orange-50 hover:text-orange-600 dark:text-zinc-400 dark:hover:bg-orange-500/10 dark:hover:text-orange-300"
                  >
                    <Icon className="h-4 w-4" />
                    {industry.label}
                  </label>
                );
              })}
            </div>

            <div className="relative overflow-hidden rounded-2xl bg-white dark:bg-zinc-950">
              {industryUseCases.map((industry) => {
                const Icon = industry.icon;

                return (
                  <div
                    key={industry.id}
                    className="hidden border border-zinc-200 p-6 dark:border-zinc-800 md:p-8"
                  >
                    <div className="grid gap-8 lg:grid-cols-2 lg:items-start">
                      <div>
                        <div className="mb-6 flex h-12 w-12 items-center justify-center rounded-2xl bg-orange-100 text-orange-600 dark:bg-orange-500/10 dark:text-orange-300">
                          <Icon className="h-6 w-6" />
                        </div>

                        <h3 className="max-w-xl text-3xl font-bold tracking-tight text-zinc-950 md:text-4xl dark:text-zinc-50">
                          {industry.title}
                        </h3>

                        <p className="mt-5 max-w-xl text-base leading-8 text-zinc-600 dark:text-zinc-400">
                          {industry.description}
                        </p>
                      </div>

                      <div className="grid gap-4 md:grid-cols-3 lg:grid-cols-1">
                        {industry.items.map((item) => (
                          <div
                            key={item.title}
                            className="rounded-2xl border border-zinc-200 bg-zinc-50 p-5 dark:border-zinc-800 dark:bg-zinc-900"
                          >
                            <h4 className="font-semibold text-zinc-950 dark:text-zinc-50">
                              {item.title}
                            </h4>

                            <p className="mt-3 text-sm leading-7 text-zinc-600 dark:text-zinc-400">
                              {item.description}
                            </p>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            <style>{`
              #industry-fintech:checked ~ div:nth-of-type(2) > div:nth-child(1),
              #industry-igaming:checked ~ div:nth-of-type(2) > div:nth-child(2),
              #industry-saas:checked ~ div:nth-of-type(2) > div:nth-child(3),
              #industry-marketplaces:checked ~ div:nth-of-type(2) > div:nth-child(4),
              #industry-platforms:checked ~ div:nth-of-type(2) > div:nth-child(5) {
                display: block;
              }

              #industry-fintech:checked ~ div:nth-of-type(1) label[for="industry-fintech"],
              #industry-igaming:checked ~ div:nth-of-type(1) label[for="industry-igaming"],
              #industry-saas:checked ~ div:nth-of-type(1) label[for="industry-saas"],
              #industry-marketplaces:checked ~ div:nth-of-type(1) label[for="industry-marketplaces"],
              #industry-platforms:checked ~ div:nth-of-type(1) label[for="industry-platforms"] {
                background: rgb(249 115 22 / 0.12);
                color: rgb(234 88 12);
              }
            `}</style>
          </div>
        </div>
      </section>

      {/* SECTION: FOOTER */}
      <footer className="bg-white dark:bg-zinc-950">
        <div className="mx-auto w-full max-w-7xl px-6 py-14">
          <div className="grid gap-10 border-b border-zinc-200 pb-10 dark:border-zinc-800 md:grid-cols-2 lg:grid-cols-4">
            <div>
              <Link
                href="/"
                className="inline-flex items-center gap-2 text-lg font-bold text-zinc-950 dark:text-zinc-50"
              >
                <Image
                  src="/img/logo.svg"
                  alt="Whooks"
                  width={120}
                  height={32}
                  className="h-7 w-auto"
                />
              </Link>

              <p className="mt-4 max-w-sm text-sm leading-7 text-zinc-600 dark:text-zinc-400">
                Open source webhook delivery infrastructure for teams that need
                reliable events, safer retries, and operational visibility.
              </p>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-zinc-950 dark:text-zinc-50">
                Introduction
              </h3>

              <div className="mt-4 space-y-3 text-sm text-zinc-600 dark:text-zinc-400">
                <Link
                  href="/docs/introduction/quickstart"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Quickstart
                </Link>

                <Link
                  href="/docs/introduction/concepts"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Concepts
                </Link>

                <Link
                  href="/docs/introduction/consuming-webhooks"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Consuming webhooks
                </Link>

                <Link
                  href="/docs/introduction/self-hosting"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Self-hosting
                </Link>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-zinc-950 dark:text-zinc-50">
                Features
              </h3>

              <div className="mt-4 space-y-3 text-sm text-zinc-600 dark:text-zinc-400">
                <Link
                  href="/docs/features/topics"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Topics
                </Link>

                <Link
                  href="/docs/features/endpoints"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Endpoints
                </Link>

                <Link
                  href="/docs/features/retries"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Retries
                </Link>

                <Link
                  href="/docs/features/idempotency"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Idempotency
                </Link>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-zinc-950 dark:text-zinc-50">
                Security
              </h3>

              <div className="mt-4 space-y-3 text-sm text-zinc-600 dark:text-zinc-400">
                <Link
                  href="/docs/security/authentication"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Authentication
                </Link>

                <Link
                  href="/docs/security/retention"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Retention
                </Link>

                <Link
                  href="/docs/features/backoffice"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Backoffice
                </Link>

                <Link
                  href="/docs/features/consumer-portal"
                  className="block transition hover:text-orange-600 dark:hover:text-orange-300"
                >
                  Consumer portal
                </Link>
              </div>
            </div>
          </div>

          <div className="flex flex-col gap-4 pt-8 text-sm text-zinc-500 dark:text-zinc-500 md:flex-row md:items-center md:justify-between">
            <p>© 2026 Whooks. Open source webhook delivery infrastructure.</p>

          </div>
        </div>
      </footer>
    </main>
  );
}