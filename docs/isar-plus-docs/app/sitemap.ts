import { MetadataRoute } from 'next';
import { source } from '@/lib/source';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
    const baseUrl = 'https://isarplus.ahmetaydin.dev';
    const languages = ['en', 'tr'];

    const urls: MetadataRoute.Sitemap = [
        {
            url: baseUrl,
            lastModified: new Date(),
            changeFrequency: 'monthly',
            priority: 1,
        },
    ];

    // Add home pages for each language
    languages.forEach((lang) => {
        urls.push({
            url: `${baseUrl}/${lang}`,
            lastModified: new Date(),
            changeFrequency: 'monthly',
            priority: 0.9,
        });
    });

    // Add all documentation pages
    languages.forEach((lang) => {
        const pages = source.getPages(lang);
        pages.forEach((page) => {
            const slug = page.url;
            urls.push({
                url: `${baseUrl}/${lang}${slug}`,
                lastModified: new Date(page.data.lastModified ?? new Date()),
                changeFrequency: 'weekly',
                priority: 0.8,
            });
        });
    });

    return urls;
}
