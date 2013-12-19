#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
 .name = KBUILD_MODNAME,
 .init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
 .exit = cleanup_module,
#endif
 .arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0x8495e121, "module_layout" },
	{ 0x1fedf0f4, "__request_region" },
	{ 0xe49685e5, "cdev_del" },
	{ 0xc6d08280, "kmalloc_caches" },
	{ 0x5a34a45c, "__kmalloc" },
	{ 0xb02fdc3a, "cdev_init" },
	{ 0xf9a482f9, "msleep" },
	{ 0x69a358a6, "iomem_resource" },
	{ 0xc7e611e3, "skb_pad" },
	{ 0x1e16bf1e, "dev_set_drvdata" },
	{ 0x88a193, "__alloc_workqueue_key" },
	{ 0x5c176503, "dma_set_mask" },
	{ 0xe4bde001, "pci_disable_device" },
	{ 0x4e6693ef, "device_destroy" },
	{ 0x26576139, "queue_work" },
	{ 0x5b19ee99, "x86_dma_fallback_dev" },
	{ 0x7485e15e, "unregister_chrdev_region" },
	{ 0x4f8b5ddb, "_copy_to_user" },
	{ 0x707ffd49, "pci_set_master" },
	{ 0x5fc25e8b, "dev_alloc_skb" },
	{ 0x8f64aa4, "_raw_spin_unlock_irqrestore" },
	{ 0x27e1a049, "printk" },
	{ 0xc4037d6a, "class_unregister" },
	{ 0x924422c3, "free_netdev" },
	{ 0xa1c76e0a, "_cond_resched" },
	{ 0x4a93ad46, "register_netdev" },
	{ 0xb4390f9a, "mcount" },
	{ 0x85763870, "netif_receive_skb" },
	{ 0x16305289, "warn_slowpath_null" },
	{ 0xfafe0694, "device_create" },
	{ 0x2072ee9b, "request_threaded_irq" },
	{ 0x1dc2191f, "dev_kfree_skb_any" },
	{ 0x149a0346, "cdev_add" },
	{ 0x42c8de35, "ioremap_nocache" },
	{ 0x3bd1b1f6, "msecs_to_jiffies" },
	{ 0xb604e62a, "kfree_skb" },
	{ 0x61e68c82, "alloc_netdev_mqs" },
	{ 0x7f923024, "eth_type_trans" },
	{ 0x7c61340c, "__release_region" },
	{ 0xf541b3ed, "pci_unregister_driver" },
	{ 0x7c11d152, "ether_setup" },
	{ 0x24f41ee7, "kmem_cache_alloc_trace" },
	{ 0x9327f5ce, "_raw_spin_lock_irqsave" },
	{ 0xe52947e7, "__phys_addr" },
	{ 0x37a0cba, "kfree" },
	{ 0x4daa6803, "pci_disable_msi" },
	{ 0xedc03953, "iounmap" },
	{ 0x3ac990db, "__pci_register_driver" },
	{ 0x480b818b, "class_destroy" },
	{ 0xa7da303b, "unregister_netdev" },
	{ 0x70107dc2, "pci_enable_msi_block" },
	{ 0x35755ca, "__netif_schedule" },
	{ 0xd80245f6, "skb_put" },
	{ 0xf8d7663c, "pci_enable_device" },
	{ 0x4f6b400b, "_copy_from_user" },
	{ 0xd7a6b38a, "__class_create" },
	{ 0x1b19af65, "dev_get_drvdata" },
	{ 0x31948a14, "dma_ops" },
	{ 0x29537c9e, "alloc_chrdev_region" },
	{ 0xf20dabd8, "free_irq" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

MODULE_ALIAS("pci:v000010EEd00004244sv*sd*bc*sc*i*");

MODULE_INFO(srcversion, "51367911526837F6FDB6678");
