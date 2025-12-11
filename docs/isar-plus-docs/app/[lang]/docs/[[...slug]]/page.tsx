import { source } from '@/lib/source';
import {
  DocsBody,
  DocsDescription,
  DocsPage,
  DocsTitle,
} from 'fumadocs-ui/page';
import { notFound } from 'next/navigation';
import { getMDXComponents } from '@/mdx-components';
import type { Metadata } from 'next';
import { LLMCopyButton, ViewOptions } from '@/components/page-actions';

export default async function Page(
  props: {
    params: Promise<{ lang: string; slug?: string[] }>;
  },
) {
  const params = await props.params;
  const page = source.getPage(params.slug, params.lang);
  if (!page) notFound();

  const MDX = page.data.body;

  // Construct URLs based on language
  const slugPath = params.slug?.join('/') || 'index';
  const langSuffix = params.lang === 'en' ? '' : `.${params.lang}`;
  const githubUrl = `https://github.com/ahmtydn/isar_plus/blob/main/docs/isar-plus-docs/content/docs/${slugPath}${langSuffix}.mdx`;

  // Markdown URL should include the slug path with language suffix
  const markdownUrl = `/${params.lang}/docs/${slugPath}${langSuffix}.mdx`;

  // Create breadcrumb schema
  const breadcrumbItems = [
    {
      '@type': 'ListItem',
      position: 1,
      name: 'Home',
      item: `https://isarplus.ahmetaydin.dev/${params.lang}`,
    },
    {
      '@type': 'ListItem',
      position: 2,
      name: 'Docs',
      item: `https://isarplus.ahmetaydin.dev/${params.lang}/docs`,
    },
  ];

  // Add slug parts to breadcrumb
  if (params.slug && params.slug.length > 0) {
    params.slug.forEach((segment, index) => {
      const path = params.slug!.slice(0, index + 1).join('/');
      breadcrumbItems.push({
        '@type': 'ListItem',
        position: index + 3,
        name: segment.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' '),
        item: `https://isarplus.ahmetaydin.dev/${params.lang}/docs/${path}`,
      });
    });
  }

  const breadcrumbSchema = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: breadcrumbItems,
  };

  const articleSchema = {
    '@context': 'https://schema.org',
    '@type': 'TechArticle',
    headline: page.data.title,
    description: page.data.description,
    dateModified: page.data.lastModified ?? new Date().toISOString(),
    author: {
      '@type': 'Organization',
      name: 'Isar Plus',
    },
    publisher: {
      '@type': 'Organization',
      name: 'Isar Plus',
      logo: {
        '@type': 'ImageObject',
        url: 'https://isarplus.ahmetaydin.dev/icon-512x512.png',
      },
    },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbSchema) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(articleSchema) }}
      />
      <DocsPage
        tableOfContent={{
          style: 'clerk',
        }}
        lastUpdate={new Date(page.data.lastModified ?? new Date())}
        toc={page.data.toc}>
        <DocsTitle>{page.data.title}</DocsTitle>
        <DocsDescription>{page.data.description}</DocsDescription>
        <div className="flex flex-row gap-2 items-center border-b pt-2 pb-6">
          <LLMCopyButton markdownUrl={markdownUrl} />
          <ViewOptions
            markdownUrl={markdownUrl}
            githubUrl={githubUrl}
          />
        </div>
        <DocsBody>
          <MDX components={getMDXComponents()} />
        </DocsBody>
      </DocsPage>
    </>
  );
}

export async function generateStaticParams() {
  return source.generateParams();
}

export async function generateMetadata(
  props: {
    params: Promise<{ lang: string; slug?: string[] }>;
  },
): Promise<Metadata> {
  const params = await props.params;
  const page = source.getPage(params.slug, params.lang);
  if (!page) notFound();

  const slugPath = params.slug?.join('/') || 'index';
  const baseUrl = 'https://isarplus.ahmetaydin.dev';
  const pageUrl = `${baseUrl}/${params.lang}/docs/${slugPath}`;
  const enUrl = `${baseUrl}/en/docs/${slugPath}`;
  const trUrl = `${baseUrl}/tr/docs/${slugPath}`;

  // Generate keywords based on page content
  const keywords = [
    'isar',
    'isar plus',
    'flutter database',
    'dart database',
    'nosql',
    'mobile database',
    'local database',
    'flutter storage',
    'dart storage',
    page.data.title.toLowerCase(),
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
      locale: params.lang === 'tr' ? 'tr_TR' : 'en_US',
      type: 'article',
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
