import { getLLMText } from '@/lib/get-llm-text';
import { source } from '@/lib/source';
import { notFound } from 'next/navigation';

export const revalidate = false;

export async function GET(
    _req: Request,
    { params }: { params: Promise<{ lang: string; slug?: string[] }> },
) {
    const { lang, slug } = await params;
    const page = source.getPage(slug, lang);
    if (!page) notFound(); return new Response(await getLLMText(page), {
        headers: {
            'Content-Type': 'text/markdown',
        },
    });
}

export function generateStaticParams() {
    return source.generateParams();
}