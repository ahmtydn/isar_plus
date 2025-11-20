import { i18n } from '@/lib/i18n';
import { NextRequest, NextResponse } from 'next/server';
import { isMarkdownPreferred, rewritePath } from 'fumadocs-core/negotiation';

const { rewrite: rewriteLLM } = rewritePath('/:lang/docs/*path', '/llms.mdx/*path');

export default function proxy(request: NextRequest) {
  const pathname = request.nextUrl.pathname;

  // Handle .mdx requests directly
  if (pathname.includes('.mdx')) {
    // Extract the path without .mdx and get the slug
    const mdxMatch = pathname.match(/\/([^/]+)\/docs\/(.+)\.mdx$/);
    if (mdxMatch) {
      const [, lang, slug] = mdxMatch;
      const newUrl = new URL(`/llms.mdx/${slug}`, request.url);
      return NextResponse.rewrite(newUrl);
    }
  }

  // Handle Accept header markdown preference
  if (isMarkdownPreferred(request)) {
    const result = rewriteLLM(pathname);
    if (result) {
      return NextResponse.rewrite(new URL(result, request.nextUrl));
    }
  }

  // Handle i18n
  const locale = i18n.defaultLanguage;
  for (const l of i18n.languages) {
    if (pathname.startsWith(`/${l}`)) {
      return NextResponse.next();
    }
  }

  if (!pathname.startsWith(`/${locale}`)) {
    return NextResponse.redirect(
      new URL(`/${locale}${pathname}`, request.url)
    );
  }

  return NextResponse.next();
}

export const config = {
  // Matcher ignoring `/_next/` and `/api/`
  // You may need to adjust it to ignore static assets in `/public` folder
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|.*\\.svg|.*\\.png|.*\\.jpg|.*\\.jpeg|.*\\.ico).*)'],
};
