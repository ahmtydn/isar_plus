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

  return (
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

  return {
    title: page.data.title,
    description: page.data.description,
  };
}
