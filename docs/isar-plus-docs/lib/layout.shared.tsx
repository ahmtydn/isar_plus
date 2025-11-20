import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import { i18n } from '@/lib/i18n';
import { BookIcon, PackageIcon } from 'lucide-react';

const titles: Record<string, string> = {
  en: 'Isar Plus',
  tr: 'Isar Plus',
};

const docLabels: Record<string, string> = {
  en: 'Documentation',
  tr: 'Dokümantasyon',
};

const pubDev: Record<string, string> = {
  en: 'Pub.dev',
  tr: 'Pub.dev',
};

export function baseOptions(locale: string): BaseLayoutProps {
  return {
    i18n,
    nav: {
      title: titles[locale] || 'Isar Plus',
      url: `/${locale}`,
    },
    githubUrl: 'https://github.com/ahmtydn/isar_plus',
    links: [
      {
        type: 'icon',
        icon: <BookIcon />,
        text: docLabels[locale] || 'Documentation',
        url: `/${locale}/docs`,
      },
      {
        type: 'icon',
        icon: <PackageIcon />,
        text: pubDev[locale] || 'Pub.dev',
        url: 'https://pub.dev/packages/isar_plus',
        external: true,
      },
    ],
  };
}
