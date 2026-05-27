const PUB_API_BASE = 'https://pub.dev/api/packages/';
const ONE_DAY_SECONDS = 60 * 60 * 24;

interface PubVersionInfo {
    version?: string;
}

interface PubSpecResponse {
    latest?: PubVersionInfo;
    versions?: PubVersionInfo[];
}

export async function getPubVersions(packageName: string): Promise<{ stable: string; dev: string }> {
    try {
        const response = await fetch(`${PUB_API_BASE}${packageName}`, {
            next: { revalidate: ONE_DAY_SECONDS },
            headers: { Accept: 'application/json' },
        });

        if (!response.ok) {
            console.error(`Failed to load versions for ${packageName}: ${response.status}`);
            return { stable: 'latest', dev: 'latest' };
        }

        const data = (await response.json()) as PubSpecResponse;
        const stable = data.latest?.version ?? 'latest';
        const allVersions = data.versions ?? [];
        const dev = allVersions.find(v =>
            v.version && /-(dev|beta|alpha|rc)/.test(v.version),
        )?.version ?? stable;

        return { stable, dev };
    } catch (error) {
        console.error(`Failed to load versions for ${packageName}:`, error);
        return { stable: 'latest', dev: 'latest' };
    }
}
