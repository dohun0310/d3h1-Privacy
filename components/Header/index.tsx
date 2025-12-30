"use client"

import Link from "next/link";
import Logo from "../Logo";

export default function Header() {
  return (
    <header className="w-full h-15 lg:h-16 top-0 left-0
      fixed z-20 bg-background
      border-b border-gray-100 dark:border-gray-800"
    >
      <div className="w-full max-w-[1325px] h-full
        relative mx-auto px-4
        flex items-center justify-between"
      >
        <Link
          href="/"
          aria-label="logo"
        >
          <Logo size={36} />
        </Link>
      </div>
    </header>
  );
}