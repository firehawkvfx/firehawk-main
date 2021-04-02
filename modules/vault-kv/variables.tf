variable "init" {
  description = "If true, will only ensure paths exist."
  type        = bool
  default     = false
}
variable "restore_defaults" {
  description = "If true, will reset all values to system defaults"
  type        = bool
  default     = false
}