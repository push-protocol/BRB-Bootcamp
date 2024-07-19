
import QuerlyLayout from "./components/QuerlyLayout";
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
          <QuerlyLayout />
          {children}
        </Querlyconfig>
      </body>
    </html>
  );
}
