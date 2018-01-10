# Discourse-OpenCollective Integration

This is a [Discourse](https://discourse.org) plugin for integrating [Opencollective.com](https://Opencollective.com). Find more about the plugin on [Discourse Meta](https://meta.discourse.org/t/discourse-opencollective-integration/69813)

![image](https://user-images.githubusercontent.com/15868287/34782946-35e80282-f650-11e7-9bfd-b40da33df1e5.png)

## Features
1. Grant a badge for the Open Collective Backers
2. Add Open Collective backers into a seperate user group 
## Installation

To install using docker, add the following to your app.yml in the plugins section:

```
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - mkdir -p plugins
          - git clone https://github.com/sudaraka94/preventing-malicious-linking-plugin
```

and rebuild docker via

```
cd /var/discourse
./launcher rebuild app
```