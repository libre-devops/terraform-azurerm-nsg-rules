# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated. They are the place to enforce module-wide consistency.

# Azure requires every rule priority in a network security group to be unique (across both
# directions). This checks the rules this module manages; note a priority could still collide with a
# rule defined elsewhere on the same NSG (apply would then fail), so keep priorities coordinated.
check "unique_rule_priorities" {
  assert {
    condition     = length(var.security_rules) == length(distinct([for r in values(var.security_rules) : r.priority]))
    error_message = "Two or more of the supplied rules share a priority. Priorities must be unique within the NSG."
  }
}

# A rules module with no rules does nothing.
check "has_rules" {
  assert {
    condition     = length(var.security_rules) > 0
    error_message = "No security_rules were supplied, so this module adds nothing to the NSG."
  }
}
