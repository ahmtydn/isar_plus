import { defineConfig, defineDocs } from 'fumadocs-mdx/config';
import { remarkVersions } from './lib/remark-versions';
import lastModified from 'fumadocs-mdx/plugins/last-modified';

export const docs = defineDocs({
  dir: 'content/docs',
});

export default defineConfig({
  plugins: [lastModified()],
  mdxOptions: {
    remarkPlugins: [remarkVersions],
    remarkCodeTabOptions: {
      parseMdx: true,
    },
  },
});
