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

func SetValueCmd() *cobra.Command {
	vip := viper.New()

	cmd := &cobra.Command{
		Use:   "set-value",
		Short: "API client for setting entitlements values",
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

			token, err := require(vip, "replicated-api-token")
			if err != nil {
				return errors.Wrapf(err, "replicated-api-token or REPLICATED_API_TOKEN")
			}

			specID, err := require(vip, "spec-id")
			if err != nil {
				return err
			}

			customerID, err := require(vip, "customer-id")
			if err != nil {
				return err
			}

			key, err := require(vip, "key")
			if err != nil {
				return err
			}

			value, err := require(vip, "value")
			if err != nil {
				return err
			}

			datatype, err := require(vip, "type")
			if err != nil {
				return err
			}

			client := &GraphQLClient{
				GQLServer: upstream,
				Token:     token,
				Logger:    stdoutLogger,
			}

			created, err := client.SetEntitlementValue(customerID, specID, key, value, datatype)

			if err != nil {
				return errors.Wrap(err, "create spec")
			}

			bytes, _ := json.MarshalIndent(created, "", "  ")
			fmt.Printf("%s\n", bytes)

			return nil
		},
	}

	cmd.Flags().String("replicated-api-token", "", "Token to use to communicate with https://g.replicated.com")
	cmd.Flags().String("replicated-app", "", "upstream g. address")
	cmd.Flags().String("spec-id", "", "spec id containing the key")
	cmd.Flags().String("customer-id", "", "customer id with which to associate value")
	cmd.Flags().String("key", "", "spec key")
	cmd.Flags().String("value", "", "value to set")
	cmd.Flags().String("type", "string", "value data type")

	cmd.Flags().String("replicated-api-server", "https://g.replicated.com/graphql", "upstream g. address")
	cmd.Flags().BoolP("verbose", "p", false, "verbose logging")

	vip.BindPFlags(cmd.Flags())
	vip.BindPFlags(cmd.PersistentFlags())
	vip.AutomaticEnv()
	vip.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))
	return cmd
}

