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
    description: "Organize events by purpose and keep delivery flows predictable.",
    href: "/docs/features/topics",
    label: "Event routing",
    icon: Boxes,
  },
  {
    title: "Endpoints",
    description: "Register consumer URLs and configure how events are delivered.",
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

export default function HomePage() {
  return (
    <main className="min-h-screen bg-background">
      <section className="mx-auto w-full max-w-6xl px-6 pb-20 pt-20 md:pt-28">
        <div className="grid items-center gap-14 md:grid-cols-[1fr_0.9fr]">
          <div>
            <div className="mb-5 inline-flex items-center gap-2 text-sm font-semibold uppercase tracking-[0.18em] text-zinc-500 dark:text-zinc-400">
              <Braces className="h-4 w-4" />
              Whooks Documentation
            </div>

            <h1 className="max-w-3xl text-4xl font-bold tracking-tight text-zinc-950 md:text-6xl dark:text-zinc-50">
              Build reliable webhook integrations with less operational risk.
            </h1>

            <p className="mt-6 max-w-2xl text-lg leading-8 text-zinc-600 dark:text-zinc-400">
              Guides, references, and implementation details to help you publish
              events, configure endpoints, handle retries, and monitor webhook
              delivery in production.
            </p>

            <div className="mt-9 flex flex-col gap-3 sm:flex-row">
              <Link
                href="/docs/introduction/quickstart"
                className="inline-flex h-11 items-center justify-center gap-2 rounded-xl bg-zinc-950 px-6 text-sm font-semibold text-white shadow-sm transition hover:bg-zinc-800 dark:bg-white dark:text-zinc-950 dark:hover:bg-zinc-200"
              >
                Get started
                <ArrowRight className="h-4 w-4" />
              </Link>

              <Link
                href="/docs/introduction"
                className="inline-flex h-11 items-center justify-center rounded-xl border border-zinc-200 bg-white px-6 text-sm font-semibold text-zinc-900 transition hover:bg-zinc-50 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-100 dark:hover:bg-zinc-900"
              >
                View documentation
              </Link>
            </div>
          </div>

          <div className="relative mx-auto w-full max-w-[500px]">
            <div className="absolute inset-8 rounded-full bg-zinc-200/60 blur-3xl dark:bg-zinc-800/60" />

            <img
              src="/img/docs-illustration.png"
              alt="Documentation illustration"
              className="relative w-full object-contain"
            />
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
            Explore Whooks
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