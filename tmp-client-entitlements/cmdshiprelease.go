package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"strings"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	"github.com/pkg/errors"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func GetShipReleaseCommand() *cobra.Command {
	vip := viper.New()

	cmd := &cobra.Command{
		Use:   "get-customer-release",
		Short: "API client for fetching the ship release payload that an end customer would receive running ship.",
		Long: `
`,
		RunE: func(cmd *cobra.Command, args []string) error {
			stdoutLogger := log.NewLogfmtLogger(os.Stdout)
			stdoutLogger = log.With(stdoutLogger, "ts", log.DefaultTimestampUTC)
			if vip.GetBool("verbose") {
				stdoutLogger = level.NewFilter(stdoutLogger, level.AllowDebug())
			} else {
				stdoutLogger = level.NewFilter(stdoutLogger, level.AllowWarn())
			}

			upstreamURL := vip.GetString("replicated-api-server")
			upstream, err := url.Parse(upstreamURL)

			if err != nil {
				return errors.Wrapf(err, "parse replicated-api-server URL %s", upstreamURL)
			}

			customerID, err := require(vip, "customer-id")
			if err != nil {
				return errors.Wrapf(err, "missing parameter")
			}

			installationID, err := require(vip, "installation-id")
			if err != nil {
				return errors.Wrapf(err, "missing parameter")
			}

			client := &PremGraphQLClient{
				GQLServer: upstream,
				CustomerID: customerID,
				InstallationID: installationID,
				Logger:    stdoutLogger,
			}

			espec, err := client.FetchCustomerRelease()

			if err != nil {
				return errors.Wrap(err, "create spec")
			}

			bytes, _ := json.MarshalIndent(espec, "", "  ")
			fmt.Printf("%s\n", bytes)

			return nil
		},
	}

	cmd.Flags().String("replicated-api-token", "", "Token to use to communicate with https://pg.replicated.com")
	cmd.Flags().String("replicated-app", "", "optional app ID or slug")
	cmd.Flags().String("customer-id", "", "customer id")
	cmd.Flags().String("installation-id", "", "installation id")

	cmd.Flags().String("replicated-api-server", "https://pg.replicated.com/graphql", "upstream pg. address")
	cmd.Flags().BoolP("verbose", "p", false, "verbose logging")

	vip.BindPFlags(cmd.Flags())
	vip.BindPFlags(cmd.PersistentFlags())
	vip.AutomaticEnv()
	vip.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))
	return cmd
}
