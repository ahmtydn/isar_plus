import 'fumadocs-ui/style.css';
import { RootProvider } from 'fumadocs-ui/provider/next';
import { Inter } from 'next/font/google';
import { defineI18nUI } from 'fumadocs-ui/i18n';
import { i18n } from '@/lib/i18n';

const inter = Inter({
  subsets: ['latin'],
});

const { provider } = defineI18nUI(i18n, {
  translations: {
    en: {
      displayName: 'English',
    },
    tr: {
      displayName: 'Türkçe',
      toc: 'İçindekiler',
      search: 'Dokümanlarda Ara',
      lastUpdate: 'Son Güncelleme',
      searchNoResult: 'Sonuç bulunamadı',
      previousPage: 'Önceki Sayfa',
      nextPage: 'Sonraki Sayfa',
      chooseLanguage: 'Dil Seçin',
    },
    de: {
      displayName: 'Deutsch',
      toc: 'Inhaltsverzeichnis',
      search: 'Dokumente durchsuchen',
      lastUpdate: 'Zuletzt aktualisiert',
      searchNoResult: 'Keine Ergebnisse',
      previousPage: 'Vorherige Seite',
      nextPage: 'Nächste Seite',
      chooseLanguage: 'Sprache wählen',
    },
    es: {
      displayName: 'Español',
      toc: 'Tabla de Contenidos',
      search: 'Buscar en Documentos',
      lastUpdate: 'Última Actualización',
      searchNoResult: 'No hay resultados',
      previousPage: 'Página Anterior',
      nextPage: 'Página Siguiente',
      chooseLanguage: 'Elegir Idioma',
    },
    fr: {
      displayName: 'Français',
      toc: 'Table des Matières',
      search: 'Rechercher dans les Documents',
      lastUpdate: 'Dernière Mise à Jour',
      searchNoResult: 'Aucun résultat',
      previousPage: 'Page Précédente',
      nextPage: 'Page Suivante',
      chooseLanguage: 'Choisir la Langue',
    },
    it: {
      displayName: 'Italiano',
      toc: 'Indice',
      search: 'Cerca nei Documenti',
      lastUpdate: 'Ultimo Aggiornamento',
      searchNoResult: 'Nessun risultato',
      previousPage: 'Pagina Precedente',
      nextPage: 'Pagina Successiva',
      chooseLanguage: 'Scegli Lingua',
    },
    ja: {
      displayName: '日本語',
      toc: '目次',
      search: 'ドキュメントを検索',
      lastUpdate: '最終更新',
      searchNoResult: '結果なし',
      previousPage: '前のページ',
      nextPage: '次のページ',
      chooseLanguage: '言語を選択',
    },
    ko: {
      displayName: '한국어',
      toc: '목차',
      search: '문서 검색',
      lastUpdate: '마지막 업데이트',
      searchNoResult: '결과 없음',
      previousPage: '이전 페이지',
      nextPage: '다음 페이지',
      chooseLanguage: '언어 선택',
    },
    pt: {
      displayName: 'Português',
      toc: 'Índice',
      search: 'Pesquisar Documentos',
      lastUpdate: 'Última Atualização',
      searchNoResult: 'Sem resultados',
      previousPage: 'Página Anterior',
      nextPage: 'Próxima Página',
      chooseLanguage: 'Escolher Idioma',
    },
    ur: {
      displayName: 'اردو',
      toc: 'فہرست',
      search: 'دستاویزات تلاش کریں',
      lastUpdate: 'آخری تازہ کاری',
      searchNoResult: 'کوئی نتیجہ نہیں',
      previousPage: 'پچھلا صفحہ',
      nextPage: 'اگلا صفحہ',
      chooseLanguage: 'زبان منتخب کریں',
    },
    zh: {
      displayName: '中文',
      toc: '目录',
      search: '搜索文档',
      lastUpdate: '最后更新',
      searchNoResult: '没有结果',
      previousPage: '上一页',
      nextPage: '下一页',
      chooseLanguage: '选择语言',
    },
  },
});

export default async function Layout({
  params,
  children,
}: LayoutProps<'/[lang]'>) {
  const { lang } = await params;
  return (
    <html lang={lang} className={inter.className} suppressHydrationWarning>
      <body
        style={{
          display: 'flex',
          flexDirection: 'column',
          minHeight: '100vh',
        }}
      >
        <RootProvider i18n={provider(lang)}>{children}</RootProvider>
      </body>
    </html>
  );
}
