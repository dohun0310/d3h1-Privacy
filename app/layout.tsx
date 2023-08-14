import { Noto_Sans_KR } from "next/font/google";

import { Header } from "@/components";
import { ThemeProvider } from "@/theme";

const noto_sans_kr = Noto_Sans_KR({
  subsets: ['latin'],
  weight: ['100', '300', '400', '500', '700', '900'],
})

export const metadata = {
  title: "d3h1 Privacy",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ko">
      <ThemeProvider>
        <body className={noto_sans_kr.className}>
          <Header />
          {children}
        </body>
      </ThemeProvider>
    </html>
  )
}
