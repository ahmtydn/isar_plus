import { visit } from 'unist-util-visit';
import type { Plugin } from 'unified';
import type { Root, Code } from 'mdast';
import { getVersions } from './versions';

/**
 * Remark plugin to replace version placeholders in code blocks
 * Replaces {versions.package_name} with actual versions from pub.dev
 */
export const remarkVersions: Plugin<[], Root> = () => {
    return async (tree, file) => {
        const versions = await getVersions();

        visit(tree, 'code', (node: Code) => {
            if (!node.value) return;

            // Replace all {versions.package_name} patterns
            let modified = node.value;
            const pattern = /\{versions\.([a-z_]+)\}/g;

            modified = modified.replace(pattern, (match, packageKey) => {
                const version = versions[packageKey];
                if (version) {
                    return version;
                }
                // If version not found, keep the placeholder
                console.warn(`Version not found for: ${packageKey}`);
                return match;
            });

            node.value = modified;
        });
    };
};
