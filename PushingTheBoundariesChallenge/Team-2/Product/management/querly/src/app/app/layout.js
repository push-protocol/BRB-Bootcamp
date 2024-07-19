import Navigator from "./navigator";
import styles from "./styles/Page.module.css";

  export const metadata = {
    title: "Querly: App",
    description: "Query Management Solution for Web3",
  };
  

  export default function AuthLayout({ children }) {
    return (
      <div className={styles.appLayout}>
        <Navigator />
        {children}
      </div>
    );
  }
  