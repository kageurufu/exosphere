"use strict";

var cloud_configs = {
  clouds: [
    {
      keystoneHostname: "js2.jetstream-cloud.org",
      friendlyName: "Jetstream2",
      friendlySubName: null,
      userAppProxy: [
        {
          region: "ASU",
          hostname: "proxy-js2-asu.exosphere.app",
        },
        {
          region: "Cornell",
          hostname: "proxy-js2-cornell.exosphere.app",
        },
        {
          region: "IU",
          hostname: "proxy-js2-iu.exosphere.app",
        },
        {
          region: "TACC",
          hostname: "proxy-js2-tacc.exosphere.app",
        },
        {
          region: "UH",
          hostname: "proxy-js2-uh.exosphere.app",
        },
        {
          region: null,
          hostname: "proxy-js2-iu.exosphere.app",
        },
      ],
      imageExcludeFilter: null,
      featuredImageNamePrefix: "Featured-",
      instanceTypes: [
        {
          friendlyName: "Ubuntu",
          description:
            "- Wide compatibility with community software packages\n\n- Good choice for new users",
          logo: "assets/img/ubuntu.svg",
          versions: [
            {
              friendlyName: "22.04 (latest)",
              isPrimary: true,
              imageFilters: {
                name: "Featured-Ubuntu22",
                visibility: "public",
              },
              restrictFlavorIds: null,
            },
            {
              friendlyName: "20.04",
              isPrimary: false,
              imageFilters: {
                name: "Featured-Ubuntu20",
                visibility: "public",
              },
              restrictFlavorIds: null,
            },
          ],
        },
        {
          friendlyName: "Red Hat-like",
          description:
            "- Based on Red Hat Enterprise Linux (RHEL)\n\n- Compatible with RPM-based software",
          logo: "assets/img/hat-fedora.svg",
          versions: [
            {
              friendlyName: "Rocky Linux 8",
              isPrimary: true,
              imageFilters: {
                name: "Featured-RockyLinux8",
                visibility: "public",
              },
              restrictFlavorIds: null,
            },
            {
              friendlyName: "AlmaLinux 8",
              isPrimary: false,
              imageFilters: {
                name: "Featured-AlmaLinux8",
                visibility: "public",
              },
              restrictFlavorIds: null,
            },
            {
              friendlyName: "CentOS 7",
              isPrimary: false,
              imageFilters: {
                name: "Featured-CentOS7",
                visibility: "public",
              },
              restrictFlavorIds: null,
            },
          ],
        },
      ],
      flavorGroups: [
        {
          matchOn: "m3..*",
          title: "General-purpose",
          description: null,
        },
        {
          matchOn: "r3..*",
          title: "Large-memory",
          description: "These have lots of RAM.",
        },
        {
          matchOn: "g3..*",
          title: "GPU",
          description: "These have a graphics processing unit.",
        },
      ],
    },
    {
      keystoneHostname: "keystone.rc.nectar.org.au",
      friendlyName: "Nectar Cloud",
      friendlySubName: null,
      userAppProxy: null,
      imageExcludeFilter: null,
      featuredImageNamePrefix: null,
      instanceTypes: [],
      flavorGroups: [],
    },
  ],
};
