import { apiInitializer } from "discourse/lib/api";
import BlockWestanHomeShowcase from "../blocks/block-westan-home-showcase";

export default apiInitializer((api) => {
  api.renderInOutlet("above-main-container", BlockWestanHomeShowcase);
});
