import Component from "@glimmer/component";
import { service } from "@ember/service";
import AsyncContent from "discourse/components/async-content";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";

export default class BlockWestanHomeShowcase extends Component {
  @service router;

  get isHomepage() {
    // Reading currentURL keeps this getter reactive during client-side
    // navigation; pathname distinguishes `/` from the separate `/latest` page.
    return Boolean(this.router.currentURL) && window.location.pathname === "/";
  }

  get quickLinks() {
    try {
      const links = Array.isArray(settings.quick_links)
        ? settings.quick_links
        : JSON.parse(settings.quick_links || "[]");
      return Array.isArray(links)
        ? links.filter((link) => link?.label?.trim() && link?.url?.trim())
        : [];
    } catch {
      return [];
    }
  }

  get hasQuickLinks() {
    return this.quickLinks.length > 0;
  }

  get criticUrl() {
    return settings.critic_url || "/critic/recent";
  }

  get rankingUrl() {
    return settings.ranking_url || "/ranking";
  }

  @bind
  async fetchHighlights() {
    const [criticResult, rankingResult] = await Promise.allSettled([
      ajax("/westan/critic/albums", {
        data: { reviewed: "true", order: "reviewed", limit: 3 },
      }),
      ajax("/westan/ranking"),
    ]);

    const critic =
      criticResult.status === "fulfilled"
        ? (criticResult.value.albums || []).slice(0, 3).map((release) => ({
            ...release,
            url: `/critic/${release.type === "single" ? "single" : "album"}/${release.slug}`,
          }))
        : [];

    const weeklyRows =
      rankingResult.status === "fulfilled"
        ? rankingResult.value.rankings?.weekly?.rows ||
          rankingResult.value.rows ||
          []
        : [];
    const topThree = weeklyRows.slice(0, 3);
    const podium = [topThree[1], topThree[0], topThree[2]]
      .filter(Boolean)
      .map((user) => ({
        ...user,
        podiumClass: `westan-home-ranking__member is-position-${user.position}`,
        profileUrl: `/u/${user.username}`,
      }));

    return {
      critic,
      podium,
      hasCritic: critic.length > 0,
      hasRanking: podium.length > 0,
    };
  }

  <template>
    {{#if this.isHomepage}}
      <section class="westan-home-showcase" aria-label="Destaques Westan">
      {{#if this.hasQuickLinks}}
        <nav
          class="westan-home-shortcuts"
          aria-label={{i18n (themePrefix "quick_access.label")}}
        >
          {{#each this.quickLinks as |link|}}
            <a href={{link.url}}>{{link.label}}</a>
          {{/each}}
        </nav>
      {{/if}}

      <AsyncContent @asyncData={{this.fetchHighlights}}>
        <:loading>
          <div class="westan-home-rail" aria-label={{i18n (themePrefix "common.loading")}}>
            <div class="westan-home-card westan-home-card--skeleton"></div>
            <div class="westan-home-card westan-home-card--skeleton"></div>
          </div>
        </:loading>

        <:content as |data|>
          <div class="westan-home-rail">
            <article class="westan-home-card westan-home-card--critic">
              <header class="westan-home-card__header">
                <div>
                  <span>{{i18n (themePrefix "critic.eyebrow")}}</span>
                  <h2>{{i18n (themePrefix "critic.title")}}</h2>
                </div>
                {{icon "star"}}
              </header>

              {{#if data.hasCritic}}
                <div class="westan-home-critic">
                  {{#each data.critic as |release|}}
                    <a class="westan-home-critic__release" href={{release.url}}>
                      <span class="westan-home-critic__cover">
                        {{#if release.cover_url}}
                          <img src={{release.cover_url}} alt="" loading="lazy" />
                        {{else}}
                          <span aria-hidden="true">♪</span>
                        {{/if}}
                      </span>
                      <strong>{{release.title}}</strong>
                      <small>{{release.artist}}</small>
                    </a>
                  {{/each}}
                </div>
              {{else}}
                <p class="westan-home-card__empty">{{i18n
                    (themePrefix "critic.empty")
                  }}</p>
              {{/if}}

              <a class="westan-home-card__cta" href={{this.criticUrl}}>
                {{i18n (themePrefix "common.check_all")}}
                {{icon "arrow-right"}}
              </a>
            </article>

            <article class="westan-home-card westan-home-card--ranking">
              <header class="westan-home-card__header">
                <div>
                  <span>{{i18n (themePrefix "ranking.eyebrow")}}</span>
                  <h2>{{i18n (themePrefix "ranking.title")}}</h2>
                </div>
                {{icon "trophy"}}
              </header>

              {{#if data.hasRanking}}
                <div class="westan-home-ranking">
                  {{#each data.podium as |user|}}
                    <a class={{user.podiumClass}} href={{user.profileUrl}}>
                      <span class="westan-home-ranking__avatar">
                        <img src={{user.avatar_url}} alt="" loading="lazy" />
                        <b>{{user.position}}</b>
                      </span>
                      <strong>{{user.display_name}}</strong>
                    </a>
                  {{/each}}
                </div>
              {{else}}
                <p class="westan-home-card__empty">{{i18n
                    (themePrefix "ranking.empty")
                  }}</p>
              {{/if}}

              <a class="westan-home-card__cta" href={{this.rankingUrl}}>
                {{i18n (themePrefix "common.check_all")}}
                {{icon "arrow-right"}}
              </a>
            </article>
          </div>
        </:content>
      </AsyncContent>
      </section>
    {{/if}}
  </template>
}
