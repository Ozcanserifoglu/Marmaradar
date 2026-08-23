package migrations

import "embed"

// FS contains every *.sql file in this directory, compiled into the API binary
// so production deploys apply pending migrations without a mounted folder.
//
//go:embed *.sql
var FS embed.FS
