import { source } from '@/lib/source';
import type { Metadata } from 'next';
import { notFound } from 'next/navigation';


export default async function HomePage({
  params,
}: {
  params: Promise<{ lang: string }>;
}) {
  const { lang } = await params;
  const page = source.getPage([], lang);
  if (!page) notFound();
  const MDX = page.data.body;

  return (
    <main className="flex-1">
      <div className="container mx-auto px-4 py-16">
        <article className="prose prose-lg dark:prose-invert max-w-none">
          <MDX />
        </article>
      </div>
    </main>
  );
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ lang: string }>;
}): Promise<Metadata> {
  const { lang } = await params;
  const page = source.getPage([], lang);
  if (!page) notFound();

  const baseUrl = 'https://isarplus.ahmetaydin.dev';
  const pageUrl = `${baseUrl}/${lang}`;
  const enUrl = `${baseUrl}/en`;
  const trUrl = `${baseUrl}/tr`;

  const keywords = [
    'isar',
    'isar plus',
    'flutter database',
    'dart database',
    'nosql database',
    'mobile database',
    'local storage',
    'flutter storage',
    'dart storage',
    'embedded database',
    'cross-platform database',
    'flutter nosql',
    'dart nosql',
    'offline database',
    'flutter local database',
    'fast database',
    'lightweight database',
  ];

  return {
    title: page.data.title,
    description: page.data.description,
    keywords,
    alternates: {
      canonical: pageUrl,
      languages: {
        'en': enUrl,
        'tr': trUrl,
        'x-default': enUrl,
      },
    },
    openGraph: {
      title: page.data.title,
      description: page.data.description,
      url: pageUrl,
      siteName: 'Isar Plus',
      locale: lang === 'tr' ? 'tr_TR' : 'en_US',
      type: 'website',
      images: [{
        url: `${baseUrl}/og-image.png`,
        width: 1200,
        height: 630,
        alt: 'Isar Plus - Ultra-fast Flutter Database',
      }],
    },
    twitter: {
      card: 'summary_large_image',
      title: page.data.title,
      description: page.data.description,
      images: [`${baseUrl}/og-image.png`],
    },
  };
}
