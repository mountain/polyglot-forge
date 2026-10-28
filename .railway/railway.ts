import { defineRailway, github, project, service } from "railway/iac";
// This repository manages only its own resources in the environment. Other
// repositories export their own partial name.
// See https://docs.railway.com/infrastructure-as-code#multi-repo-projects
export const partial = "polyglot-forge";
export default defineRailway(() => {
  const polyglotForge = service("polyglot-forge", {
    // builder from CaC: "NIXPACKS"
    source: github("mountain/polyglot-forge", { branch: "main", checkSuites: false }),
    start: "uvicorn app:app --host 0.0.0.0 --port $PORT",
    healthcheck: "/healthz",
    healthcheckTimeout: 120,
    replicas: { "asia-southeast1-eqsg3a": 1 },
  });

  return project("angelic-healing", {
    variables: { managed: false },
    resources: [polyglotForge],
  });
});
