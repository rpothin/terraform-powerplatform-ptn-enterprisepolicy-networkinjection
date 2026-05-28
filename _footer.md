<!-- TODO (before publishing to Terraform Registry): Replace the relative links below
     with absolute GitHub URLs, e.g.:
       See [CONTRIBUTING.md](https://github.com/<OWNER>/<REPO>/blob/main/CONTRIBUTING.md)
     Relative paths work on GitHub but 404 on the Terraform Registry. -->

## AVM Alignment

This module is aligned with [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/) conventions. The following known deviations apply:

| ID | Category | Description |
|----|----------|-------------|
| D1 | Provider scope | This module requires three providers (`microsoft/power-platform`, `hashicorp/azurerm`, `azure/azapi`). AVM pattern modules typically use a single provider. The multi-provider design is necessary because Power Platform VNet injection requires both ARM resources (via azapi/azurerm) and Power Platform API resources (via power-platform). |
| D2 | Registry namespace | Published under `rpothin/ptn-enterprisepolicy-networkinjection/powerplatform` (Power Platform namespace) rather than the AVM-preferred `Azure/` organization on the Terraform Registry, because the Power Platform provider is maintained separately from the Azure provider ecosystem. |
| D3 | Test tooling | Uses `terraform test` (native Terraform testing framework) rather than the AVM-recommended Go/Terratest framework, as the Power Platform provider does not have a Go SDK suitable for integration with Terratest at this time. |
| D7 | Telemetry beacon | This module does not include an `azapi_resource` telemetry beacon (as required by AVM TELEM1). The Power Platform provider does not support the ARM deployment telemetry pattern, and adding a standalone ARM deployment solely for telemetry would introduce unnecessary Azure subscription side effects for callers who only need Power Platform resources. |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Support

See [SUPPORT.md](SUPPORT.md) for support information.

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
