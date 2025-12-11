const PUB_API_BASE = 'https://pub.dev/api/packages/';
const ONE_DAY_SECONDS = 60 * 60 * 24;

interface PubSpecResponse {
    latest?: {
        version?: string;
    };
}

export async function getPubVersion(packageName: string): Promise<string> {
    try {
        const response = await fetch(`${PUB_API_BASE}${packageName}`, {
            next: { revalidate: ONE_DAY_SECONDS },
            headers: { Accept: 'application/json' },
        });

        if (!response.ok) {
            console.error(`Failed to load version for ${packageName}: ${response.status}`);
            return 'latest';
        }

        const data = (await response.json()) as PubSpecResponse;
        return data.latest?.version ?? 'latest';
    } catch (error) {
        console.error(`Failed to load version for ${packageName}:`, error);
        return 'latest';
    }
}
