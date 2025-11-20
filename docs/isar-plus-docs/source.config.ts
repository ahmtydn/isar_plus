import { defineConfig, defineDocs } from 'fumadocs-mdx/config';
import { remarkVersions } from './lib/remark-versions';

export const docs = defineDocs({
  dir: 'content/docs',
});

export default defineConfig({
  mdxOptions: {
    remarkPlugins: [remarkVersions],
    remarkCodeTabOptions: {
      parseMdx: true,
    },
  },
});
