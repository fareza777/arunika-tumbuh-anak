import "./index.css";
import { MyComposition, StoreCompositions } from "./Composition";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <MyComposition />
      <StoreCompositions />
    </>
  );
};
