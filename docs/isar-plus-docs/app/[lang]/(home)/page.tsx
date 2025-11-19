import { DynamicLink } from 'fumadocs-core/dynamic-link';
import { RocketIcon, DatabaseIcon, ZapIcon, ShieldCheckIcon } from 'lucide-react';

export default function HomePage() {
  return (
    <main className="flex-1">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center mb-16">
          <h1 className="text-5xl font-bold mb-4 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
            Isar Plus
          </h1>
          <p className="text-xl text-muted-foreground mb-8">
            High-performance NoSQL database for Flutter & Dart
          </p>
          <div className="flex gap-4 justify-center">
            <DynamicLink
              href="/[lang]/docs"
              className="px-6 py-3 bg-primary text-primary-foreground rounded-lg font-semibold hover:opacity-90 transition-opacity"
            >
              Get Started
            </DynamicLink>
            <a
              href="https://github.com/ahmtydn/isar_plus"
              target="_blank"
              rel="noopener noreferrer"
              className="px-6 py-3 border border-border rounded-lg font-semibold hover:bg-accent transition-colors"
            >
              View on GitHub
            </a>
          </div>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
          <div className="p-6 border border-border rounded-lg">
            <RocketIcon className="w-12 h-12 mb-4 text-blue-500" />
            <h3 className="text-lg font-semibold mb-2">Blazing Fast</h3>
            <p className="text-sm text-muted-foreground">
              Optimized for mobile with incredible performance
            </p>
          </div>
          <div className="p-6 border border-border rounded-lg">
            <DatabaseIcon className="w-12 h-12 mb-4 text-purple-500" />
            <h3 className="text-lg font-semibold mb-2">Feature Rich</h3>
            <p className="text-sm text-muted-foreground">
              Indexes, queries, links, transactions, and more
            </p>
          </div>
          <div className="p-6 border border-border rounded-lg">
            <ZapIcon className="w-12 h-12 mb-4 text-yellow-500" />
            <h3 className="text-lg font-semibold mb-2">Easy to Use</h3>
            <p className="text-sm text-muted-foreground">
              Type-safe API with code generation
            </p>
          </div>
          <div className="p-6 border border-border rounded-lg">
            <ShieldCheckIcon className="w-12 h-12 mb-4 text-green-500" />
            <h3 className="text-lg font-semibold mb-2">ACID Compliant</h3>
            <p className="text-sm text-muted-foreground">
              Reliable transactions with automatic rollback
            </p>
          </div>
        </div>

        <div className="bg-accent/50 rounded-lg p-8 text-center">
          <h2 className="text-2xl font-bold mb-4">Ready to get started?</h2>
          <p className="text-muted-foreground mb-6">
            Follow our quick start guide and build your first app with Isar Plus
          </p>
          <DynamicLink
            href="/[lang]/docs/quickstart"
            className="inline-block px-6 py-3 bg-primary text-primary-foreground rounded-lg font-semibold hover:opacity-90 transition-opacity"
          >
            Quick Start →
          </DynamicLink>
        </div>
      </div>
    </main>
  );
}
