import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import BottomTabs from "@/components/BottomTabs";
import TopBar from "@/components/TopBar";
import FTUEModal from "@/components/FTUEModal";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "SparkQuest V2",
  description: "The ultimate AI dating and gaming experience.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.className} bg-zinc-950 text-white antialiased w-full h-screen fixed overflow-hidden flex justify-center items-center`}>
        {/* Mobile App Container (iPhone Simulator on Desktop) */}
        <div id="app-container" className="relative w-full max-w-[390px] h-[100dvh] sm:h-[90vh] sm:max-h-[844px] bg-black sm:shadow-[0_0_50px_rgba(0,0,0,0.8)] sm:rounded-[3rem] sm:border-[12px] sm:border-zinc-900 flex flex-col overflow-hidden ring-1 ring-white/10 mx-auto">
          
          {/* Fake iPhone Notch (Desktop only) */}
          <div className="hidden sm:block absolute top-0 left-1/2 -translate-x-1/2 w-[120px] h-[30px] bg-zinc-900 rounded-b-3xl z-[999999]"></div>
          
          <FTUEModal />
          
          <TopBar />

          <main className="flex-1 relative z-10 overflow-y-auto hide-scrollbar pb-[70px]">
            {children}
          </main>
          
          <div className="absolute bottom-0 w-full z-50">
            <BottomTabs />
          </div>
        </div>
      </body>
    </html>
  );
}
