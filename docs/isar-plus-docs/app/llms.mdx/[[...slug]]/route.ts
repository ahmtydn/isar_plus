import { getLLMText } from '@/lib/get-llm-text';
import { source } from '@/lib/source';
import { notFound } from 'next/navigation';

export const revalidate = false;

type RouteContext<T extends string> = {
    params: Promise<Record<T, string[]>>;
};

export async function GET(
    _req: Request,
    { params }: RouteContext<'slug'>,
) {
    const { slug } = await params;
    const page = source.getPage(slug);
    if (!page) notFound();

    return new Response(await getLLMText(page), {
        headers: {
            'Content-Type': 'text/markdown',
        },
    });
}

export function generateStaticParams() {
    return source.generateParams();
}
