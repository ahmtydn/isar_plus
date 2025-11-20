import { source } from '@/lib/source';
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
