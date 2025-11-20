import 'fumadocs-ui/style.css';
import { RootProvider } from 'fumadocs-ui/provider/next';
import { Inter } from 'next/font/google';
import { defineI18nUI } from 'fumadocs-ui/i18n';
import { i18n } from '@/lib/i18n';
import type { ReactNode } from 'react';
import type { Metadata } from 'next';

const inter = Inter({
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: {
    default: 'Isar Plus - Ultra-fast Flutter Database',
    template: '%s | Isar Plus',
  },
  description: 'Isar Plus is an ultra-fast, easy-to-use database for Flutter and Dart applications',
  icons: {
    icon: [
      { url: '/icon-256x256.png', sizes: '256x256', type: 'image/png' },
      { url: '/icon-512x512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [
      { url: '/icon-256x256.png', sizes: '256x256', type: 'image/png' },
    ],
  },
};

const { provider } = defineI18nUI(i18n, {
  translations: {
    en: {
      displayName: 'English',
      toc: 'Table of Contents',
      search: 'Search in Documents',
      lastUpdate: 'Last Update',
      searchNoResult: 'No results found',
      previousPage: 'Previous Page',
      nextPage: 'Next Page',
      chooseLanguage: 'Choose Language',
    },
    tr: {
      displayName: 'Türkçe',
      toc: 'İçindekiler',
      search: 'Dokümanlarda Ara',
      lastUpdate: 'Son Güncelleme',
      searchNoResult: 'Sonuç bulunamadı',
      previousPage: 'Önceki Sayfa',
      nextPage: 'Sonraki Sayfa',
      chooseLanguage: 'Dil Seçin',
    },
  },
});

export default async function Layout({
  params,
  children,
}: {
  params: Promise<{ lang: string }>;
  children: ReactNode;
}) {
  const { lang } = await params;
  return (
    <html lang={lang} className={inter.className} suppressHydrationWarning>
      <body
        style={{
          display: 'flex',
          flexDirection: 'column',
          minHeight: '100vh',
        }}
      >
        <RootProvider i18n={provider(lang)}>{children}</RootProvider>
      </body>
    </html>
  );
}
