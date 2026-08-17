import { apiInitializer } from "discourse/lib/api";
import BlockWestanHomeShowcase from "../blocks/block-westan-home-showcase";

export default apiInitializer((api) => {
  api.renderBlocks("homepage-blocks", [
    {
      block: BlockWestanHomeShowcase,
      id: "westan-home-showcase",
      args: {
        quickLinksJson: JSON.stringify(settings.quick_links || []),
        criticUrl: settings.critic_url,
        rankingUrl: settings.ranking_url,
      },
      conditions: { type: "route", pages: ["HOMEPAGE"] },
    },
  ]);
});
