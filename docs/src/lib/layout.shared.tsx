import type { BaseLayoutProps } from "fumadocs-ui/layouts/shared";
import { appName, gitConfig } from "./shared";
import { Logo } from "@/components/logo";

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      // JSX supported
      title: (
        <div className="flex items-center gap-2 h-6">
          <Logo />
          <span>{appName}</span>
        </div>
      ),
    },
    githubUrl: `https://github.com/${gitConfig.user}/${gitConfig.repo}`,
  };
}
