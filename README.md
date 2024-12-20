This is a sample code for a minimal estimation agent to be used with [Carbon DB](https://www.green-coding.io/projects/carbondb/)

The agent will read the CPU utilization through a supplied script.

The estimation for the machine power comes from [Cloud Energy](https://www.green-coding.io/projects/cloud-energy/).

## Installation

Create a user space `systemd` service with:

```bash
cp carbondb_agent.service ~/.config/systemd/user/
systemctl --user enable carbondb_agent.service
systemctl --user start carbondb_agent.service
```

You must also set your `API_TOKEN` in the file `machine_energy_carbondb.sh`

Done. It will send data every 60 seconds and will be restarted on reboot or fail.

## Creating energy estimations
Estimation agents are used when no direct power values can be obtained from a system.

Cloud Energy is able to create energy estimations based on the current CPU utilization on a system.

In order to transform the CPU utilization to an energy value we need to know which specs the machine has we are on and also additionally what virtualization ratio we have.
Virtualization ratio means what share of the total machine our VM has on the bare metal system.

### Example - Hetzner CAX21
We are using a [Hetzner CAX21](https://search.brave.com/search?q=hetzner+cax21&source=desktop) which has 4 Threads and 8 GB DRAM.

Assumption is that shared plans use the same machine as the current bare metal: Q80-30 Source: https://www.hetzner.com/dedicated-rootserver/matrix-rx/

The Q80-30 has 80 cores with 3 GHz and also 80 Threads. Source: https://amperecomputing.com/briefs/ampere-altra-family-product-brief and

TDP of 250 W comes from here: https://en.wikipedia.org/wiki/Ampere_Computing

The virtualization leven is 0.05. This comes from the ratio 4/80. Since we have 4 cores assigned from 80 of the bare metal systems.
This sounds reasonable also when looking at the DRAM. The total bare metal box would then have 160 GB or RAM spread over 10 channels, which is a typical configuration for a data center server.

Now we can leverage Cloud Energy and run:
`python3 xgb.py --cpu-threads 80 --cpu-cores 80 --cpu-freq 3000 --cpu-chips 1 --tdp 250 --ram 160 --vhost-ratio 0.05`

Note that we put in here the un-virtualized values and then apply he virtualizatiion factor as a separate argument. This is very important, because otherwise you will get very skewed values.

#### Example Hetzner CAX11

This example is for a [Hetzner CAX11](https://search.brave.com/search?q=hetzner+cax11&source=desktop) which has 2 Threads and 4 GB DRAM. Note that only the vhost ratio changes 
compared to the prior example.

`python3 xgb.py --cpu-threads 80 --cpu-cores 80 --cpu-freq 3000 --cpu-chips 1 --tdp 250 --ram 160 --vhost-ratio 0.025`

The generated power profile file is not part of the repo, but you can generate it with:

`python3 xgb.py --cpu-threads 80 --cpu-cores 80 --cpu-freq 3000 --cpu-chips 1 --tdp 250 --ram 160 --vhost-ratio 0.025 --dump-hashmap`

#### Example Hetzner CPX11

This example is for a [Hetzner CPX1](https://search.brave.com/search?q=hetzner+cax21&source=desktop) which has 2 Threads and 2 GB DRAM.

Assumpt is that the shared plan uses a [AMD EPYC™ 7702](https://www.amd.com/de/products/processors/server/epyc/7002-series.html) which
has 64 Cores, 128 Threads and a TDP of 200 W with a 2 GHz Base Frequency.

`python3 xgb.py --cpu-threads 128 --cpu-cores 64 --cpu-freq 2000 --cpu-chips 1 --tdp 200 --ram 128 --vhost-ratio 0.015625`