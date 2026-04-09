"""initial schema

Revision ID: 20260408_0001
Revises:
Create Date: 2026-04-08
"""

from alembic import op
import sqlalchemy as sa


revision = "20260408_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("email", sa.String(), nullable=False),
        sa.Column("hashed_password", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=True),
        sa.Column("bio", sa.String(), nullable=True),
        sa.Column("age", sa.Integer(), nullable=True),
        sa.Column("gender", sa.String(), nullable=True),
        sa.Column("intent", sa.String(), nullable=True),
        sa.Column("city", sa.String(), nullable=True),
        sa.Column("interests", sa.String(), nullable=True),
        sa.Column("is_verified", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_banned", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("last_active_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_users_id"), "users", ["id"], unique=False)
    op.create_index(op.f("ix_users_email"), "users", ["email"], unique=True)

    op.create_table(
        "interactions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("actor_user_id", sa.Integer(), nullable=False),
        sa.Column("target_user_id", sa.Integer(), nullable=False),
        sa.Column("action", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["target_user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("actor_user_id", "target_user_id", name="uq_interaction_pair"),
    )
    op.create_index(op.f("ix_interactions_id"), "interactions", ["id"], unique=False)
    op.create_index(op.f("ix_interactions_actor_user_id"), "interactions", ["actor_user_id"], unique=False)
    op.create_index(op.f("ix_interactions_target_user_id"), "interactions", ["target_user_id"], unique=False)

    op.create_table(
        "matches",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_a_id", sa.Integer(), nullable=False),
        sa.Column("user_b_id", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["user_a_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["user_b_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_a_id", "user_b_id", name="uq_match_pair"),
    )
    op.create_index(op.f("ix_matches_id"), "matches", ["id"], unique=False)
    op.create_index(op.f("ix_matches_user_a_id"), "matches", ["user_a_id"], unique=False)
    op.create_index(op.f("ix_matches_user_b_id"), "matches", ["user_b_id"], unique=False)

    op.create_table(
        "chat_threads",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("match_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["match_id"], ["matches.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("match_id", name="uq_thread_match"),
    )
    op.create_index(op.f("ix_chat_threads_id"), "chat_threads", ["id"], unique=False)
    op.create_index(op.f("ix_chat_threads_match_id"), "chat_threads", ["match_id"], unique=False)

    op.create_table(
        "messages",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("thread_id", sa.Integer(), nullable=False),
        sa.Column("sender_user_id", sa.Integer(), nullable=False),
        sa.Column("content", sa.String(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["thread_id"], ["chat_threads.id"]),
        sa.ForeignKeyConstraint(["sender_user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_messages_id"), "messages", ["id"], unique=False)
    op.create_index(op.f("ix_messages_thread_id"), "messages", ["thread_id"], unique=False)
    op.create_index(op.f("ix_messages_sender_user_id"), "messages", ["sender_user_id"], unique=False)

    op.create_table(
        "user_blocks",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("blocker_user_id", sa.Integer(), nullable=False),
        sa.Column("blocked_user_id", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["blocker_user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["blocked_user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("blocker_user_id", "blocked_user_id", name="uq_block_pair"),
    )
    op.create_index(op.f("ix_user_blocks_id"), "user_blocks", ["id"], unique=False)
    op.create_index(op.f("ix_user_blocks_blocker_user_id"), "user_blocks", ["blocker_user_id"], unique=False)
    op.create_index(op.f("ix_user_blocks_blocked_user_id"), "user_blocks", ["blocked_user_id"], unique=False)

    op.create_table(
        "user_reports",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("reporter_user_id", sa.Integer(), nullable=False),
        sa.Column("reported_user_id", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="open"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["reporter_user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["reported_user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_user_reports_id"), "user_reports", ["id"], unique=False)
    op.create_index(op.f("ix_user_reports_reporter_user_id"), "user_reports", ["reporter_user_id"], unique=False)
    op.create_index(op.f("ix_user_reports_reported_user_id"), "user_reports", ["reported_user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_user_reports_reported_user_id"), table_name="user_reports")
    op.drop_index(op.f("ix_user_reports_reporter_user_id"), table_name="user_reports")
    op.drop_index(op.f("ix_user_reports_id"), table_name="user_reports")
    op.drop_table("user_reports")

    op.drop_index(op.f("ix_user_blocks_blocked_user_id"), table_name="user_blocks")
    op.drop_index(op.f("ix_user_blocks_blocker_user_id"), table_name="user_blocks")
    op.drop_index(op.f("ix_user_blocks_id"), table_name="user_blocks")
    op.drop_table("user_blocks")

    op.drop_index(op.f("ix_messages_sender_user_id"), table_name="messages")
    op.drop_index(op.f("ix_messages_thread_id"), table_name="messages")
    op.drop_index(op.f("ix_messages_id"), table_name="messages")
    op.drop_table("messages")

    op.drop_index(op.f("ix_chat_threads_match_id"), table_name="chat_threads")
    op.drop_index(op.f("ix_chat_threads_id"), table_name="chat_threads")
    op.drop_table("chat_threads")

    op.drop_index(op.f("ix_matches_user_b_id"), table_name="matches")
    op.drop_index(op.f("ix_matches_user_a_id"), table_name="matches")
    op.drop_index(op.f("ix_matches_id"), table_name="matches")
    op.drop_table("matches")

    op.drop_index(op.f("ix_interactions_target_user_id"), table_name="interactions")
    op.drop_index(op.f("ix_interactions_actor_user_id"), table_name="interactions")
    op.drop_index(op.f("ix_interactions_id"), table_name="interactions")
    op.drop_table("interactions")

    op.drop_index(op.f("ix_users_email"), table_name="users")
    op.drop_index(op.f("ix_users_id"), table_name="users")
    op.drop_table("users")
