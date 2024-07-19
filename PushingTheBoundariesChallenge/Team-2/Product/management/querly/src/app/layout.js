
import "./globals.css";
import dynamic from "next/dynamic";
const Querlyconfig = dynamic(() => import("./config/QuerlyConfig"), {
  ssr: false,
});

export const metadata = {
  title: "Querly",
  description: "Query Management System for Web3",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        <Querlyconfig>
          {children}
        </Querlyconfig>
      </body>
    </html>
  );
}
